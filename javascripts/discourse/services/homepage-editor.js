import { cached, tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import Service, { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { currentThemeId } from "discourse/lib/theme-selector";
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

function generateId() {
  if (typeof crypto !== "undefined" && crypto.randomUUID) {
    return crypto.randomUUID();
  }
  return `b_${Date.now()}_${Math.random().toString(36).slice(2)}`;
}

function withId(entry) {
  return entry.id ? entry : { ...entry, id: generateId() };
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
  @service siteSettings;
  @service toasts;

  @tracked layout = [];
  @tracked editing = false;
  @tracked saving = false;
  @tracked dirty = false;
  @tracked picking = false;
  @tracked pickerInsertAfter = null;
  @tracked configuringIndex = null;
  @tracked welcomeBannerEnabled = false;

  themeId = null;
  _savedSnapshot = "[]";
  _savedWelcomeBannerEnabled = false;

  load(rawSetting) {
    const raw = rawSetting || "[]";
    try {
      const parsed = JSON.parse(raw);
      this.layout = Array.isArray(parsed) ? parsed.map(withId) : [];
    } catch {
      this.layout = [];
    }
    this._savedSnapshot = JSON.stringify(this.layout);
    this.welcomeBannerEnabled = !!this.siteSettings.enable_welcome_banner;
    this._savedWelcomeBannerEnabled = this.welcomeBannerEnabled;
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
    this.welcomeBannerEnabled = this._savedWelcomeBannerEnabled;
    this.dirty = false;
    this.editing = false;
    this.configuringIndex = null;
    this.picking = false;
    this.pickerInsertAfter = null;
  }

  @action
  toggleWelcomeBanner() {
    this.welcomeBannerEnabled = !this.welcomeBannerEnabled;
    this.dirty = true;
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
    this.layout = [
      ...this.layout,
      { id: generateId(), type, args: defaultArgsFor(type) },
    ];
    this.dirty = true;
  }

  @action
  insertHalfBlockAfter(type, afterIndex) {
    const next = this.layout.slice();
    next.splice(afterIndex + 1, 0, {
      id: generateId(),
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
  get itemsForRender() {
    const items = [];
    rowsFromLayout(this.layout).forEach((row) => {
      row.indices.forEach((i) => {
        const entry = this.layout[i];
        items.push({
          kind: "block",
          entry,
          index: i,
          key: entry.id,
        });
      });
      if (row.width === "half" && row.indices.length === 1) {
        const i = row.indices[0];
        items.push({
          kind: "empty-half",
          afterIndex: i,
          key: `empty-${this.layout[i].id}`,
        });
      }
    });
    return items;
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

  async saveWelcomeBannerSettings() {
    if (this.welcomeBannerEnabled === this._savedWelcomeBannerEnabled) {
      return;
    }
    const parentThemeId = currentThemeId();
    if (!parentThemeId) {
      throw new Error("Could not resolve current theme id.");
    }
    await ajax(`/admin/themes/${parentThemeId}/site-setting`, {
      type: "PUT",
      data: { name: "enable_welcome_banner", value: this.welcomeBannerEnabled },
    });
    this.siteSettings.enable_welcome_banner = this.welcomeBannerEnabled;
    if (this.welcomeBannerEnabled) {
      await ajax("/admin/site_settings/welcome_banner_page_visibility", {
        type: "PUT",
        data: { welcome_banner_page_visibility: "homepage" },
      });
      this.siteSettings.welcome_banner_page_visibility = "homepage";
    }
    this._savedWelcomeBannerEnabled = this.welcomeBannerEnabled;
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
      await this.saveWelcomeBannerSettings();
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
