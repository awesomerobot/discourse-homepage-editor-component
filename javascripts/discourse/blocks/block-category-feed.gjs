import Component from "@glimmer/component";
import { cached } from "@glimmer/tracking";
import { htmlSafe } from "@ember/template";
import icon from "discourse/helpers/d-icon";
import Category from "discourse/models/category";
import { or } from "truth-helpers";

export default class BlockCategoryFeed extends Component {
  @cached
  get categories() {
    const ids = this.args.args?.categoryIds || [];
    return ids.map((id) => Category.findById(Number(id))).filter(Boolean);
  }

  <template>
    <div class="hpe-block-category-feed">
      {{#each this.categories as |category|}}
        <a class="hpe-block-category-feed__card" href={{category.url}}>
          <div class="hpe-block-category-feed__icon">
            {{icon (or category.icon "folder")}}
          </div>
          <div class="hpe-block-category-feed__text">
            <h3 class="hpe-block-category-feed__name">{{category.name}}</h3>
            {{#if category.description_excerpt}}
              <p class="hpe-block-category-feed__description">
                {{htmlSafe category.description_excerpt}}
              </p>
            {{/if}}
          </div>
        </a>
      {{/each}}
    </div>
  </template>
}
