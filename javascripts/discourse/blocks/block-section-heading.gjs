import Component from "@glimmer/component";
import DButton from "discourse/components/d-button";
import { and } from "truth-helpers";

export default class BlockSectionHeading extends Component {
  <template>
    <div class="hpe-block-section-heading">
      <h2 class="hpe-block-section-heading__title">
        {{#if @args.buttonLink}}
          <a href={{@args.buttonLink}}>{{@args.title}}</a>
        {{else}}
          {{@args.title}}
        {{/if}}
      </h2>
      {{#if (and @args.buttonLabel @args.buttonLink)}}
        <DButton
          class="btn-default hpe-block-section-heading__button"
          @icon={{@args.buttonIcon}}
          @href={{@args.buttonLink}}
          @translatedLabel={{@args.buttonLabel}}
        />
      {{/if}}
    </div>
  </template>
}
