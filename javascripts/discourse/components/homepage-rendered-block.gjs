import Component from "@glimmer/component";
import { service } from "@ember/service";
import { getBlockDef } from "../lib/block-registry";
import HomepageBlockControls from "./homepage-block-controls";

export default class HomepageRenderedBlock extends Component {
  @service homepageEditor;

  get def() {
    return getBlockDef(this.args.entry.type);
  }

  get componentClass() {
    return this.def?.component;
  }

  get blockArgs() {
    return this.args.entry.args || {};
  }

  get width() {
    return this.args.entry.width === "half" ? "half" : "full";
  }

  <template>
    {{#if this.componentClass}}
      <div
        class="hpe-row hpe-row--{{this.width}}"
        data-block-type={{@entry.type}}
        data-width={{this.width}}
      >
        {{#if this.homepageEditor.editing}}
          <HomepageBlockControls @index={{@index}} @entry={{@entry}} />
        {{/if}}

        <div class="hpe-row__content">
          {{#let this.componentClass as |Block|}}
            <Block @args={{this.blockArgs}} />
          {{/let}}
        </div>
      </div>
    {{/if}}
  </template>
}
