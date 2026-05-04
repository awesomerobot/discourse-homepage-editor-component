import BlockCategoryFeed from "../blocks/block-category-feed";
import BlockFeaturedList from "../blocks/block-featured-list";
import BlockHeroBanner from "../blocks/block-hero-banner";
import BlockHtml from "../blocks/block-html";
import BlockLeaderboard from "../blocks/block-leaderboard";
import BlockSectionHeading from "../blocks/block-section-heading";
import BlockTopicCards from "../blocks/block-topic-cards";

// Each entry describes:
//   - component: the block component to render
//   - label: human-readable name for the picker
//   - fields: form fields for the editor. Each field is
//       { name, label, type, default?, options?, help? }
//     types: "text", "textarea", "url", "number", "color", "boolean",
//            "category", "categories", "tag", "image", "select"
export const BLOCK_REGISTRY = {
  "hero-banner": {
    component: BlockHeroBanner,
    label: "Hero banner",
    fields: [
      { name: "title", label: "Title", type: "text" },
      { name: "description", label: "Description", type: "textarea" },
      { name: "backgroundImage", label: "Background image", type: "image" },
      { name: "backgroundColor", label: "Background color", type: "color" },
      { name: "textColor", label: "Text color", type: "color" },
    ],
  },
  "section-heading": {
    component: BlockSectionHeading,
    label: "Section heading",
    fields: [
      { name: "title", label: "Title", type: "text" },
      { name: "buttonLabel", label: "Button label", type: "text" },
      { name: "buttonLink", label: "Button link", type: "url" },
      {
        name: "buttonIcon",
        label: "Button icon",
        type: "text",
        help: "Font Awesome icon name (no fa- prefix)",
      },
    ],
  },
  "category-feed": {
    component: BlockCategoryFeed,
    label: "Category feed",
    fields: [
      { name: "categoryIds", label: "Categories", type: "categories" },
    ],
  },
  "featured-list": {
    component: BlockFeaturedList,
    label: "Topic list",
    fields: [
      { name: "title", label: "Heading", type: "text" },
      {
        name: "filter",
        label: "Filter",
        type: "select",
        default: "latest",
        options: [
          { value: "latest", label: "Latest" },
          { value: "top", label: "Top" },
          { value: "new", label: "New" },
          { value: "unread", label: "Unread" },
          { value: "hot", label: "Hot" },
        ],
      },
      { name: "count", label: "Number of topics", type: "number", default: 5 },
      { name: "categoryId", label: "Limit to category", type: "category" },
      { name: "tag", label: "Limit to tag", type: "tag" },
      {
        name: "seeAllLabel",
        label: "See all button label",
        type: "text",
        help: "Leave blank to hide the button. The URL is derived from the filter and category/tag above.",
      },
    ],
  },
  "topic-cards": {
    component: BlockTopicCards,
    label: "Topic cards",
    fields: [
      { name: "title", label: "Heading", type: "text" },
      {
        name: "filter",
        label: "Filter",
        type: "select",
        default: "latest",
        options: [
          { value: "latest", label: "Latest" },
          { value: "top", label: "Top" },
          { value: "new", label: "New" },
          { value: "unread", label: "Unread" },
          { value: "hot", label: "Hot" },
        ],
      },
      { name: "count", label: "Number of topics", type: "number", default: 4 },
      {
        name: "layout",
        label: "Layout",
        type: "select",
        default: "auto",
        options: [
          { value: "auto", label: "Auto (responsive)" },
          { value: "2", label: "2 per row" },
          { value: "3", label: "3 per row" },
          { value: "4", label: "4 per row" },
          { value: "single-row", label: "Single row (one per topic on large screens)" },
        ],
      },
      { name: "hideMeta", label: "Hide metadata (category, author, date)", type: "boolean" },
      { name: "categoryId", label: "Limit to category", type: "category" },
      { name: "tag", label: "Limit to tag", type: "tag" },
      {
        name: "seeAllLabel",
        label: "See all button label",
        type: "text",
        help: "Leave blank to hide the button. The URL is derived from the filter and category/tag above.",
      },
    ],
  },
  leaderboard: {
    component: BlockLeaderboard,
    label: "Leaderboard",
    fields: [
      { name: "title", label: "Title override", type: "text" },
      { name: "leaderboardId", label: "Leaderboard ID", type: "number" },
      { name: "count", label: "Number of users", type: "number", default: 10 },
      {
        name: "seeAllLabel",
        label: "See all button label",
        type: "text",
        help: "Leave blank to hide the button. Links to the leaderboard page.",
      },
    ],
  },
  html: {
    component: BlockHtml,
    label: "Raw HTML",
    fields: [{ name: "html", label: "HTML", type: "textarea" }],
  },
};

export function blockTypes() {
  return Object.entries(BLOCK_REGISTRY).map(([key, def]) => ({
    type: key,
    label: def.label,
  }));
}

export function getBlockDef(type) {
  return BLOCK_REGISTRY[type];
}
