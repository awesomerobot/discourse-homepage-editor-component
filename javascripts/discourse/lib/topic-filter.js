import getURL from "discourse/lib/get-url";
import Category from "discourse/models/category";

function tagName(tag) {
  if (!tag) {
    return null;
  }
  if (typeof tag === "string") {
    return tag;
  }
  return tag.name || null;
}

export function topicFilterFindArgs({ filterType, categoryId, tag }) {
  const tagSlug = tagName(tag);
  if (categoryId) {
    const category = Category.findById(categoryId);
    if (category) {
      const filter = `c/${Category.slugFor(category)}/${category.id}/l/${filterType}`;
      return tagSlug ? { filter, params: { tags: [tagSlug] } } : { filter };
    }
  }
  if (tagSlug) {
    return { filter: `tag/${tagSlug}/l/${filterType}` };
  }
  return { filter: filterType };
}

export function topicFilterSeeAllUrl({ filterType, categoryId, tag }) {
  const tagSlug = tagName(tag);
  if (categoryId) {
    const category = Category.findById(categoryId);
    if (category) {
      const base = `/c/${Category.slugFor(category)}/${category.id}/l/${filterType}`;
      return getURL(
        tagSlug ? `${base}?tags=${encodeURIComponent(tagSlug)}` : base
      );
    }
  }
  if (tagSlug) {
    return getURL(`/tag/${encodeURIComponent(tagSlug)}/l/${filterType}`);
  }
  return getURL(`/${filterType}`);
}
