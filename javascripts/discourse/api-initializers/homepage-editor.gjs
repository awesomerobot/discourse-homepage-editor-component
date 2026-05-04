import { apiInitializer } from "discourse/lib/api";
import HomepageContainer from "../components/homepage-container";

export default apiInitializer((api) => {
  const editor = api.container.lookup("service:homepage-editor");
  editor.load(settings.homepage_blocks);

  api.renderBlocks("homepage-blocks", [
    { block: HomepageContainer, id: "homepage-editor-container" },
  ]);
});
