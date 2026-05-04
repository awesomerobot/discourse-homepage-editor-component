import DButton from "discourse/components/d-button";
import avatar from "discourse/helpers/avatar";
import number from "discourse/helpers/number";
import { ajax } from "discourse/lib/ajax";
import getURL from "discourse/lib/get-url";
import CachedAsyncBlock from "../lib/cached-async-block";

export default class BlockLeaderboard extends CachedAsyncBlock {
  get config() {
    return this.args.args || {};
  }

  get fetchKey() {
    return [
      this.config.leaderboardId,
      this.config.count,
      this.config.title,
    ].join("|");
  }

  get seeAllUrl() {
    return getURL(
      this.config.leaderboardId
        ? `/leaderboard/${this.config.leaderboardId}`
        : "/leaderboard"
    );
  }

  async fetchData() {
    const count = this.config.count || 10;
    const id = this.config.leaderboardId;
    const endpoint = id ? `/leaderboard/${id}` : "/leaderboard";
    const model = await ajax(endpoint, { data: { user_limit: count } });
    return {
      title: this.config.title || model.leaderboard?.name,
      users: model.users || [],
    };
  }

  <template>
    {{#if this.loadedData.isPending}}
      <div class="hpe-block-leaderboard__loading"><div
          class="spinner"
        ></div></div>
    {{else if this.loadedData.value}}
      {{#let this.loadedData.value as |data|}}
        <div class="hpe-block-leaderboard">
          {{#if data.title}}
            <h2 class="hpe-block-leaderboard__title">
              {{#if @args.seeAllLabel}}
                <a href={{this.seeAllUrl}}>{{data.title}}</a>
              {{else}}
                {{data.title}}
              {{/if}}
            </h2>
          {{/if}}
          <ol class="hpe-block-leaderboard__list">
            {{#each data.users as |user|}}
              <li class="hpe-block-leaderboard__row">
                <div class="hpe-block-leaderboard__user">
                  {{avatar user imageSize="small"}}
                  <span>{{user.username}}</span>
                </div>
                <div class="hpe-block-leaderboard__score">
                  {{number user.total_score}}
                </div>
              </li>
            {{/each}}
          </ol>
          {{#if @args.seeAllLabel}}
            <div class="hpe-block-leaderboard__footer">
              <DButton
                class="btn-default hpe-block-leaderboard__see-all"
                @href={{this.seeAllUrl}}
                @translatedLabel={{@args.seeAllLabel}}
                @icon="arrow-right"
              />
            </div>
          {{/if}}
        </div>
      {{/let}}
    {{/if}}
  </template>
}
