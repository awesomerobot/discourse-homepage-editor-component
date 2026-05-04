import { concat } from "@ember/helper";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import DButton from "discourse/components/d-button";
import UserLink from "discourse/components/user-link";
import avatar from "discourse/helpers/avatar";
import { categoryLinkHTML } from "discourse/helpers/category-link";
import formatDate from "discourse/helpers/format-date";
import getURL from "discourse/lib/get-url";
import Category from "discourse/models/category";
import { i18n } from "discourse-i18n";
import CachedAsyncBlock from "../lib/cached-async-block";
import { topicFilterFindArgs, topicFilterSeeAllUrl } from "../lib/topic-filter";

export default class BlockTopicCards extends CachedAsyncBlock {
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

  get layoutClass() {
    const layout = this.config.layout || "auto";
    return layout === "auto" ? "" : `hpe-block-topic-cards--${layout}`;
  }

  get gridStyle() {
    if (this.config.layout === "single-row") {
      return htmlSafe(`--hpe-card-count: ${this.config.count || 4}`);
    }
    return null;
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
    const topics = topicList.topics
      .slice(0, this.config.count || 4)
      .map((topic) => ({
        ...topic,
        category: Category.findById(topic.category_id),
        creator: topic.posters?.[0]?.user || null,
      }));
    return {
      topics,
      anyHasImage: topics.some((t) => !!t.image_url),
    };
  }

  topicHref(topic) {
    return getURL(`/t/${topic.slug}/${topic.id}`);
  }

  <template>
    <div class="hpe-block-topic-cards__wrapper">
      {{#if @args.title}}
        <h2 class="hpe-block-topic-cards__title">
          {{#if @args.seeAllLabel}}
            <a href={{this.seeAllUrl}}>{{@args.title}}</a>
          {{else}}
            {{@args.title}}
          {{/if}}
        </h2>
      {{/if}}

      {{#if this.loadedData.isPending}}
        <div class="hpe-block-topic-cards__loading">
          <div class="spinner"></div>
        </div>
      {{else if this.loadedData.value}}
        {{#let this.loadedData.value as |data|}}
          <div class="hpe-block-topic-cards {{this.layoutClass}}" style={{this.gridStyle}}>
            {{#each data.topics as |topic|}}
              <a class="hpe-block-topic-cards__card" href={{this.topicHref topic}}>
                {{#if data.anyHasImage}}
                  {{#if topic.image_url}}
                    <div
                      class="hpe-block-topic-cards__image"
                      style={{htmlSafe
                        (concat "background-image: url(" topic.image_url ")")
                      }}
                    ></div>
                  {{else}}
                    <div class="hpe-block-topic-cards__image hpe-block-topic-cards__image--placeholder"></div>
                  {{/if}}
                {{/if}}

                <div class="hpe-block-topic-cards__body">
                  {{#unless @args.hideMeta}}
                    {{#if topic.category}}
                      <div class="hpe-block-topic-cards__category">
                        {{categoryLinkHTML topic.category}}
                      </div>
                    {{/if}}
                  {{/unless}}
                  <h3 class="hpe-block-topic-cards__topic-title">
                    {{htmlSafe topic.fancy_title}}
                  </h3>
                  {{#if topic.excerpt}}
                    <p class="hpe-block-topic-cards__excerpt">
                      {{htmlSafe topic.excerpt}}
                    </p>
                  {{/if}}
                  {{#unless @args.hideMeta}}
                    <div class="hpe-block-topic-cards__meta">
                      {{#if topic.creator}}
                        <UserLink
                          class="hpe-block-topic-cards__author"
                          @user={{topic.creator}}
                        >
                          {{avatar topic.creator imageSize="small"}}
                          <span>{{topic.creator.username}}</span>
                        </UserLink>
                      {{/if}}
                      <span class="hpe-block-topic-cards__date">
                        {{formatDate topic.bumped_at format="tiny"}}
                      </span>
                    </div>
                  {{/unless}}
                </div>
              </a>
            {{/each}}
          </div>
        {{/let}}
      {{else}}
        <div class="hpe-block-topic-cards__empty">
          {{i18n "topics.none.latest"}}
        </div>
      {{/if}}

      {{#if @args.seeAllLabel}}
        <div class="hpe-block-topic-cards__footer">
          <DButton
            class="btn-default hpe-block-topic-cards__see-all"
            @href={{this.seeAllUrl}}
            @translatedLabel={{@args.seeAllLabel}}
            @icon="arrow-right"
          />
        </div>
      {{/if}}
    </div>
  </template>
}
