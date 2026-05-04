import { service } from "@ember/service";
import BasicTopicList from "discourse/components/basic-topic-list";
import DButton from "discourse/components/d-button";
import { i18n } from "discourse-i18n";
import CachedAsyncBlock from "../lib/cached-async-block";
import { topicFilterFindArgs, topicFilterSeeAllUrl } from "../lib/topic-filter";

export default class BlockFeaturedList extends CachedAsyncBlock {
  @service store;
  @service currentUser;

  get config() {
    return this.args.args || {};
  }

  get filterType() {
    return this.config.filter || "latest";
  }

  get fetchKey() {
    return [
      this.filterType,
      this.config.count,
      this.config.categoryId,
      this.config.tag,
    ].join("|");
  }

  get seeAllUrl() {
    return topicFilterSeeAllUrl({
      filterType: this.filterType,
      categoryId: this.config.categoryId,
      tag: this.config.tag,
    });
  }

  async fetchData() {
    if (["new", "unread"].includes(this.filterType) && !this.currentUser) {
      return null;
    }

    const findArgs = topicFilterFindArgs({
      filterType: this.filterType,
      categoryId: this.config.categoryId,
      tag: this.config.tag,
    });
    const topicList = await this.store.findFiltered("topicList", findArgs);
    if (!topicList.topics?.length) {
      return null;
    }
    return topicList.topics.slice(0, this.config.count || 5);
  }

  <template>
    <div class="hpe-block-featured-list__wrapper">
      {{#if @args.title}}
        <h2 class="hpe-block-featured-list__title">
          {{#if @args.seeAllLabel}}
            <a href={{this.seeAllUrl}}>{{@args.title}}</a>
          {{else}}
            {{@args.title}}
          {{/if}}
        </h2>
      {{/if}}

      {{#if this.loadedData.isPending}}
        <div class="hpe-block-featured-list__loading"><div
            class="spinner"
          ></div></div>
      {{else if this.loadedData.value}}
        <BasicTopicList
          @topics={{this.loadedData.value}}
          @showPosters="true"
          class="hpe-block-featured-list"
        />
      {{else}}
        <div class="hpe-block-featured-list__empty">
          {{i18n "topics.none.latest"}}
        </div>
      {{/if}}

      {{#if @args.seeAllLabel}}
        <div class="hpe-block-featured-list__footer">
          <DButton
            class="btn-default hpe-block-featured-list__see-all"
            @href={{this.seeAllUrl}}
            @translatedLabel={{@args.seeAllLabel}}
            @icon="arrow-right"
          />
        </div>
      {{/if}}
    </div>
  </template>
}
