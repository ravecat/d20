import { addons } from "storybook/manager-api";

addons.setConfig({
  layout: {
    panelPosition: "right",
    rightPanelWidth: 400,
  },
  layoutCustomisations: {
    showPanel: () => true,
  },
  sidebar: {
    renderLabel: ({ name }) => name.replace(/∕/g, "/"),
  },
});
