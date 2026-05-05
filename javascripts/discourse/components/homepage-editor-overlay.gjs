import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import icon from "discourse/helpers/d-icon";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";
import { blockTypes } from "../lib/block-registry";

export default class HomepageEditorOverlay extends Component {
  @service homepageEditor;
  @service siteSettings;

  get blockTypes() {
    return blockTypes(this.siteSettings);
  }

  <template>
    <div class="hpe-toolbar">
      <div class="hpe-toolbar__left">
        {{#if this.homepageEditor.editing}}
          <strong>{{i18n (themePrefix "homepage_editor.toolbar.editing")}}</strong>
        {{/if}}
        {{#if this.homepageEditor.dirty}}
          <span class="hpe-toolbar__dirty">
            {{icon "triangle-exclamation"}}
            {{i18n (themePrefix "homepage_editor.toolbar.unsaved")}}
          </span>
        {{/if}}
        {{#if this.homepageEditor.editing}}
          <DButton
            class="btn-transparent"
            @action={{this.homepageEditor.cancelEditing}}
            @icon="xmark"
          />
        {{/if}}
      </div>
      <div class="hpe-toolbar__right">
        {{#if this.homepageEditor.editing}}
          <div class="hpe-toolbar__welcome-banner">
            <DToggleSwitch
              @state={{this.homepageEditor.welcomeBannerEnabled}}
              @label={{themePrefix "homepage_editor.toolbar.welcome_banner"}}
              {{on "click" this.homepageEditor.toggleWelcomeBanner}}
            />
            <a
              class="hpe-toolbar__welcome-banner-config"
              href={{getURL "/admin/config/welcome-banner"}}
              target="_blank"
              rel="noopener"
              title={{i18n
                (themePrefix "homepage_editor.toolbar.welcome_banner_config")
              }}
            >
              {{icon "gear"}}
            </a>
          </div>
          <div class="hpe-toolbar__actions">
            <DButton
              class="btn-default"
              @action={{this.homepageEditor.openPicker}}
              @icon="plus"
              @label={{themePrefix "homepage_editor.toolbar.add"}}
            />
            <DButton
              class="btn-primary"
              @action={{this.homepageEditor.save}}
              @disabled={{this.homepageEditor.saving}}
              @isLoading={{this.homepageEditor.saving}}
              @icon="check"
              @label={{themePrefix "homepage_editor.toolbar.save"}}
            />
          </div>
        {{else}}
          <DButton
            class="btn-default"
            @action={{this.homepageEditor.toggleEditing}}
            @icon="pencil"
            @label={{themePrefix "homepage_editor.toolbar.edit"}}
          />
        {{/if}}
      </div>
    </div>

    {{#if this.homepageEditor.picking}}
      <div
        class="hpe-picker__backdrop"
        role="button"
        {{on "click" this.homepageEditor.closePicker}}
      ></div>
      <div class="hpe-picker">
        <h3 class="hpe-picker__title">
          {{i18n (themePrefix "homepage_editor.picker.title")}}
        </h3>
        <div class="hpe-picker__grid">
          {{#each this.blockTypes as |bt|}}
            <button
              type="button"
              class="hpe-picker__option"
              {{on "click" (fn this.homepageEditor.pickType bt.type)}}
            >
              {{bt.label}}
            </button>
          {{/each}}
        </div>
      </div>
    {{/if}}
  </template>
}
