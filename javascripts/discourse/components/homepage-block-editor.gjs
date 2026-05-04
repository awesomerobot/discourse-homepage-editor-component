import Component from "@glimmer/component";
import { cached } from "@glimmer/tracking";
import { array, hash } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import getURL from "discourse/lib/get-url";
import { eq } from "truth-helpers";
import CategoryChooser from "select-kit/components/category-chooser";
import MultiSelect from "select-kit/components/multi-select";
import TagChooser from "select-kit/components/tag-chooser";
import { getBlockDef } from "../lib/block-registry";

const TYPE_TO_FK = {
  text: "input",
  url: "input-url",
  color: "input-color",
  textarea: "textarea",
  number: "input-number",
  select: "select",
  boolean: "checkbox",
};

export default class HomepageBlockEditor extends Component {
  @service homepageEditor;
  @service site;

  get fields() {
    return getBlockDef(this.args.entry.type)?.fields || [];
  }

  @cached
  get formData() {
    return { ...(this.args.entry.args || {}) };
  }

  fkType = (type) => TYPE_TO_FK[type] || "custom";

  @action
  handleSubmit(data) {
    this.homepageEditor.updateBlock(this.args.index, data);
    this.homepageEditor.closeConfig();
  }

  @action
  handleImageSet(upload, { set, name }) {
    if (!upload) {
      set(name, null);
      return;
    }
    set(name, upload.url ? getURL(upload.url) : null);
  }

  @action
  handleTagSet(values, { set, name }) {
    const v = Array.isArray(values) ? values[0] : values;
    if (!v) {
      set(name, null);
      return;
    }
    set(name, typeof v === "string" ? v : v.name || null);
  }

  @action
  handleCategoriesSet(values, { set, name }) {
    set(name, (values || []).map((v) => Number(v)));
  }

  <template>
    <Form
      @data={{this.formData}}
      @onSubmit={{this.handleSubmit}}
      class="hpe-block-form"
      as |form|
    >
      {{#each this.fields as |field|}}
        {{#if (eq field.type "select")}}
          <form.Field
            @name={{field.name}}
            @title={{field.label}}
            @type="select"
            @helpText={{field.help}}
            as |fkField|
          >
            <fkField.Control as |select|>
              {{#each field.options as |opt|}}
                <select.Option @value={{opt.value}}>{{opt.label}}</select.Option>
              {{/each}}
            </fkField.Control>
          </form.Field>
        {{else if (eq field.type "category")}}
          <form.Field
            @name={{field.name}}
            @title={{field.label}}
            @type="custom"
            @helpText={{field.help}}
            as |fkField|
          >
            <fkField.Control>
              <CategoryChooser
                @value={{fkField.value}}
                @onChange={{fkField.set}}
                @options={{hash none=true clearable=true}}
              />
            </fkField.Control>
          </form.Field>
        {{else if (eq field.type "categories")}}
          <form.Field
            @name={{field.name}}
            @title={{field.label}}
            @type="custom"
            @helpText={{field.help}}
            @onSet={{this.handleCategoriesSet}}
            as |fkField|
          >
            <fkField.Control>
              <MultiSelect
                @value={{fkField.value}}
                @content={{this.site.categories}}
                @nameProperty="name"
                @valueProperty="id"
                @onChange={{fkField.set}}
              />
            </fkField.Control>
          </form.Field>
        {{else if (eq field.type "tag")}}
          <form.Field
            @name={{field.name}}
            @title={{field.label}}
            @type="custom"
            @helpText={{field.help}}
            @onSet={{this.handleTagSet}}
            as |fkField|
          >
            <fkField.Control>
              <TagChooser
                @tags={{if fkField.value (array fkField.value)}}
                @onChange={{fkField.set}}
                @options={{hash maximum=1}}
              />
            </fkField.Control>
          </form.Field>
        {{else if (eq field.type "image")}}
          <form.Field
            @name={{field.name}}
            @title={{field.label}}
            @type="image"
            @helpText={{field.help}}
            @onSet={{this.handleImageSet}}
            as |fkField|
          >
            <fkField.Control @type="homepage_block_image" />
          </form.Field>
        {{else}}
          <form.Field
            @name={{field.name}}
            @title={{field.label}}
            @type={{this.fkType field.type}}
            @helpText={{field.help}}
            as |fkField|
          >
            <fkField.Control />
          </form.Field>
        {{/if}}
      {{/each}}

      <form.Actions>
        <form.Submit @label={{themePrefix "homepage_editor.form.save"}} />
      </form.Actions>
    </Form>
  </template>
}
