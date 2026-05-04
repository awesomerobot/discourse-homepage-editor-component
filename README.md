# Discourse Homepage Editor

A theme component that turns the Discourse custom homepage into a WYSIWYG layout editor. Admins compose the homepage from inline-configurable rows (blocks) without leaving the page.

## How it works

- Sets the `custom_homepage` theme modifier so `/` becomes the editable layout.
- Stores layout in a single JSON theme setting (`homepage_blocks`).
- Renders one container block via `api.renderBlocks("homepage-blocks", ...)`;
  the container reads tracked layout state from a service so live edits
  re-render immediately.
- Admins see an "Edit homepage" toolbar. In edit mode each row gets
  move/delete controls and a collapsible field editor. The "Add block" button
  opens a picker.
- Saving PUTs to `/admin/themes/:id/setting` (the component finds its own
  theme id by name on first save).

## Block types

- Hero banner
- Section heading
- Category feed
- Topic list (filter by latest/top/new/unread/hot, optional category/tag)
- Leaderboard (requires `discourse-gamification`)
- Raw HTML

## Adding a new block type

1. Create a Glimmer component in `javascripts/discourse/blocks/` that reads
   from `@args.<argName>`.
2. Register it in `javascripts/discourse/lib/block-registry.js` with a
   `label` and `fields` array.
3. The editor form picks up the new fields automatically.

## Caveats

- The component identifies itself by the `name` field in `about.json`
  (`Discourse Homepage Editor`). Renaming that requires updating
  `COMPONENT_NAME` in `services/homepage-editor.js`.
- Only admins can save. Non-admins always see the rendered layout.
