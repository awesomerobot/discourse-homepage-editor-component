import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";

export default class BlockHeroBanner extends Component {
  get style() {
    const a = this.args.args || {};
    const parts = [];
    if (a.backgroundColor) {
      parts.push(`--hero-bg: ${a.backgroundColor}`);
    }
    if (a.textColor) {
      parts.push(`--hero-fg: ${a.textColor}`);
    }
    if (a.backgroundImage) {
      parts.push(`--hero-image: url('${a.backgroundImage}')`);
    }
    return parts.length ? htmlSafe(parts.join(";")) : null;
  }

  get hasImage() {
    return !!this.args.args?.backgroundImage;
  }

  <template>
    <div
      class="hpe-block-hero-banner {{if this.hasImage 'has-image'}}"
      style={{this.style}}
    >
      <h1 class="hpe-block-hero-banner__title">{{@args.title}}</h1>
      {{#if @args.description}}
        <p class="hpe-block-hero-banner__description">{{@args.description}}</p>
      {{/if}}
    </div>
  </template>
}
