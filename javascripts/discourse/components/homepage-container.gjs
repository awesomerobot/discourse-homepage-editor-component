import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { service } from "@ember/service";
import { block } from "discourse/blocks";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import { i18n } from "discourse-i18n";
import { eq } from "truth-helpers";
import { getBlockDef } from "../lib/block-registry";
import HomepageBlockEditor from "./homepage-block-editor";
import HomepageEditorOverlay from "./homepage-editor-overlay";
import HomepageRenderedBlock from "./homepage-rendered-block";

@block("theme:homepage-editor:container", {
  description: "Container for the homepage editor blocks",
})
export default class HomepageContainer extends Component {
  @service homepageEditor;

  get configuringEntry() {
    const idx = this.homepageEditor.configuringIndex;
    if (idx === null || idx === undefined) {
      return null;
    }
    return this.homepageEditor.layout[idx] || null;
  }

  get configuringTitle() {
    const entry = this.configuringEntry;
    if (!entry) {
      return i18n(themePrefix("homepage_editor.block.configure"));
    }
    const def = getBlockDef(entry.type);
    return i18n(themePrefix("homepage_editor.block.configure_named"), {
      label: def?.label || entry.type,
    });
  }

  <template>
    <div
      class="hpe-homepage"
      data-editing={{if this.homepageEditor.editing "true"}}
    >
      {{#if this.homepageEditor.canEdit}}
        <HomepageEditorOverlay />
      {{/if}}

      <div class="hpe-homepage__rows">
        {{#each this.homepageEditor.rowsForRender key="@index" as |row|}}
          {{#if (eq row.type "full")}}
            <HomepageRenderedBlock @entry={{row.entry}} @index={{row.index}} />
          {{else}}
            {{#each row.slots key="index" as |slot|}}
              <HomepageRenderedBlock @entry={{slot.entry}} @index={{slot.index}} />
            {{/each}}
            {{#if (eq row.slots.length 1)}}
              <div class="hpe-row hpe-row--half hpe-row--empty">
                <DButton
                  class="btn-default hpe-row--empty__add"
                  @action={{fn
                    this.homepageEditor.openPicker
                    row.lonelyAfterIndex
                  }}
                  @icon="plus"
                  @label={{themePrefix "homepage_editor.block.add"}}
                />
              </div>
            {{/if}}
          {{/if}}
        {{/each}}
      </div>

      {{#if this.configuringEntry}}
        <DModal
          @title={{this.configuringTitle}}
          @closeModal={{this.homepageEditor.closeConfig}}
          class="hpe-block-config-modal"
        >
          <:body>
            <HomepageBlockEditor
              @index={{this.homepageEditor.configuringIndex}}
              @entry={{this.configuringEntry}}
            />
          </:body>
        </DModal>
      {{/if}}
    </div>
  </template>
}
