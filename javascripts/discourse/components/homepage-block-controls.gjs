import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { i18n } from "discourse-i18n";
import { getBlockDef } from "../lib/block-registry";

export default class HomepageBlockControls extends Component {
  @service homepageEditor;

  get label() {
    return getBlockDef(this.args.entry.type)?.label || this.args.entry.type;
  }

  get isHalf() {
    return this.args.entry.width === "half";
  }

  get widthIcon() {
    return this.isHalf ? "circle-half-stroke" : "circle";
  }

  get widthLabel() {
    return i18n(
      themePrefix(
        this.isHalf
          ? "homepage_editor.block.width.half"
          : "homepage_editor.block.width.full"
      )
    );
  }

  get widthTitle() {
    return i18n(
      themePrefix(
        this.isHalf
          ? "homepage_editor.block.width.switch_to_full"
          : "homepage_editor.block.width.switch_to_half"
      )
    );
  }


  @action
  remove() {
    this.homepageEditor.removeBlock(this.args.index);
  }

  @action
  toggleWidth() {
    this.homepageEditor.toggleWidth(this.args.index);
  }

  @action
  openConfig() {
    this.homepageEditor.openConfig(this.args.index);
  }

  <template>
    <div class="hpe-row__controls">
      <span class="hpe-row__label">{{this.label}}</span>
      <div class="hpe-row__buttons">
        <DButton
          class="btn-flat hpe-row__width-toggle"
          @icon={{this.widthIcon}}
          @translatedLabel={{this.widthLabel}}
          @action={{this.toggleWidth}}
          @translatedTitle={{this.widthTitle}}
        />
        <DButton
          class="btn-flat"
          @icon="arrow-up"
          @action={{fn this.homepageEditor.moveBlock @index -1}}
          @title={{themePrefix "homepage_editor.block.move_up"}}
        />
        <DButton
          class="btn-flat"
          @icon="arrow-down"
          @action={{fn this.homepageEditor.moveBlock @index 1}}
          @title={{themePrefix "homepage_editor.block.move_down"}}
        />
        <DButton
          class="btn-flat"
          @icon="gear"
          @action={{this.openConfig}}
          @title={{themePrefix "homepage_editor.block.configure"}}
        />
        <DButton
          class="btn-flat btn-danger"
          @icon="trash-can"
          @action={{this.remove}}
          @title={{themePrefix "homepage_editor.block.delete"}}
        />
      </div>
    </div>
  </template>
}
