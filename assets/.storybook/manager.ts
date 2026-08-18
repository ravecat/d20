import { addons } from "storybook/manager-api";

addons.setConfig({
  layout: {
    panelPosition: "right",
    showPanel: true,
  },
  layoutCustomisations: {
    showPanel: () => true,
  },
});
