import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";

// eslint-disable-next-line ember/no-empty-glimmer-component-classes
export default class BlockHtml extends Component {
  <template>
    <div class="hpe-block-html">{{htmlSafe @args.html}}</div>
  </template>
}
