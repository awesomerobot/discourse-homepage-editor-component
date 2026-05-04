import { cached, tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import Service, { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";
import { getBlockDef } from "../lib/block-registry";

const SETTING_NAME = "homepage_blocks";
const COMPONENT_NAME = "Discourse Homepage Editor";

function defaultArgsFor(type) {
  const def = getBlockDef(type);
  if (!def) {
    return {};
  }
  const args = {};
  for (const field of def.fields || []) {
    if (field.default !== undefined) {
      args[field.name] = field.default;
    }
  }
  return args;
}

// Group consecutive half-width blocks into pairs (max 2 per row).
// Full-width blocks each get their own row.
function rowsFromLayout(layout) {
  const rows = [];
  let current = null;
  layout.forEach((entry, idx) => {
    if (entry.width === "half") {
      if (current?.width === "half" && current.indices.length < 2) {
        current.indices.push(idx);
      } else {
        current = { width: "half", indices: [idx] };
        rows.push(current);
      }
    } else {
      current = { width: "full", indices: [idx] };
      rows.push(current);
    }
  });
  return rows;
}

export default class HomepageEditor extends Service {
  @service currentUser;
  @service toasts;

  @tracked layout = [];
  @tracked editing = false;
  @tracked saving = false;
  @tracked dirty = false;
  @tracked picking = false;
  @tracked pickerInsertAfter = null;
  @tracked configuringIndex = null;

  themeId = null;
  _savedSnapshot = "[]";

  load(rawSetting) {
    const raw = rawSetting || "[]";
    try {
      const parsed = JSON.parse(raw);
      this.layout = Array.isArray(parsed) ? parsed : [];
    } catch {
      this.layout = [];
    }
    this._savedSnapshot = JSON.stringify(this.layout);
    this.dirty = false;

    if (this.canEdit) {
      this.resolveThemeId().catch(() => {});
    }
  }

  get canEdit() {
    return this.currentUser?.admin;
  }

  @action
  toggleEditing() {
    this.editing = !this.editing;
  }

  @action
  cancelEditing() {
    this.layout = JSON.parse(this._savedSnapshot);
    this.dirty = false;
    this.editing = false;
    this.configuringIndex = null;
    this.picking = false;
    this.pickerInsertAfter = null;
  }

  @action
  updateBlock(index, args) {
    const current = this.layout[index];
    if (!current) {
      return;
    }
    const merged = { ...current.args, ...args };
    const unchanged = Object.keys(args).every(
      (k) => current.args?.[k] === args[k]
    );
    if (unchanged) {
      return;
    }
    const next = this.layout.slice();
    next[index] = { ...current, args: merged };
    this.layout = next;
    this.dirty = true;
  }

  @action
  addBlock(type) {
    this.layout = [...this.layout, { type, args: defaultArgsFor(type) }];
    this.dirty = true;
  }

  @action
  insertHalfBlockAfter(type, afterIndex) {
    const next = this.layout.slice();
    next.splice(afterIndex + 1, 0, {
      type,
      args: defaultArgsFor(type),
      width: "half",
    });
    this.layout = next;
    this.dirty = true;
  }

  @action
  openPicker(insertAfter = null) {
    this.pickerInsertAfter = insertAfter;
    this.picking = true;
  }

  @action
  closePicker() {
    this.picking = false;
    this.pickerInsertAfter = null;
  }

  @action
  openConfig(index) {
    this.configuringIndex = index;
  }

  @action
  closeConfig() {
    this.configuringIndex = null;
  }

  @action
  pickType(type) {
    if (this.pickerInsertAfter !== null) {
      this.insertHalfBlockAfter(type, this.pickerInsertAfter);
    } else {
      this.addBlock(type);
    }
    this.closePicker();
  }

  @action
  removeBlock(index) {
    const next = this.layout.slice();
    next.splice(index, 1);
    this.layout = next;
    this.dirty = true;
    if (this.configuringIndex === index) {
      this.configuringIndex = null;
    }
  }

  @cached
  get rowsForRender() {
    return rowsFromLayout(this.layout).map((row) => {
      if (row.width === "half") {
        const slots = row.indices.map((i) => ({
          entry: this.layout[i],
          index: i,
        }));
        return {
          type: "halves",
          slots,
          lonelyAfterIndex: slots.length === 1 ? slots[0].index : null,
        };
      }
      return {
        type: "full",
        entry: this.layout[row.indices[0]],
        index: row.indices[0],
      };
    });
  }

  @action
  moveBlock(index, delta) {
    const entry = this.layout[index];
    if (!entry) {
      return;
    }

    if (entry.width === "half") {
      const target = index + delta;
      if (target < 0 || target >= this.layout.length) {
        return;
      }
      const next = this.layout.slice();
      [next[index], next[target]] = [next[target], next[index]];
      this.layout = next;
    } else {
      const rows = rowsFromLayout(this.layout);
      const sourceRowIdx = rows.findIndex((r) => r.indices.includes(index));
      const targetRowIdx = sourceRowIdx + delta;
      if (
        sourceRowIdx < 0 ||
        targetRowIdx < 0 ||
        targetRowIdx >= rows.length
      ) {
        return;
      }
      const reordered = rows.slice();
      [reordered[sourceRowIdx], reordered[targetRowIdx]] = [
        reordered[targetRowIdx],
        reordered[sourceRowIdx],
      ];
      this.layout = reordered.flatMap((row) =>
        row.indices.map((i) => this.layout[i])
      );
    }
    this.dirty = true;
  }

  @action
  toggleWidth(index) {
    const next = this.layout.slice();
    const entry = next[index];
    if (!entry) {
      return;
    }
    next[index] = { ...entry, width: entry.width === "half" ? "full" : "half" };
    this.layout = next;
    this.dirty = true;
  }

  async resolveThemeId() {
    if (this.themeId) {
      return this.themeId;
    }
    const data = await ajax("/admin/customize/themes.json");
    const themes = data?.themes || [];
    const match = themes.find(
      (t) => t.component && t.name === COMPONENT_NAME
    );
    if (!match) {
      throw new Error(
        `Could not find theme component named "${COMPONENT_NAME}".`
      );
    }
    this.themeId = match.id;
    return this.themeId;
  }

  @action
  async save() {
    if (this.saving) {
      return;
    }
    this.saving = true;
    try {
      const id = await this.resolveThemeId();
      const payload = JSON.stringify(this.layout);
      await ajax(`/admin/themes/${id}/setting`, {
        type: "PUT",
        data: { name: SETTING_NAME, value: payload },
      });
      this._savedSnapshot = payload;
      this.dirty = false;
      this.editing = false;
      this.toasts.success({
        duration: 3000,
        data: {
          message: i18n(themePrefix("homepage_editor.toolbar.saved")),
        },
      });
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.saving = false;
    }
  }
}
