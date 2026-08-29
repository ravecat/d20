import type { Preview } from "@storybook/svelte-vite";
import { withThemeByDataAttribute } from "@storybook/addon-themes";
import "../css/app.css";

const preview: Preview = {
  decorators: [
    // Sets data-theme on the preview html element (the addon's default parent),
    // so theme tokens, color-scheme, and the root scrollbar follow the toolbar
    // selection instead of the browser's prefers-color-scheme.
    withThemeByDataAttribute({
      themes: {
        light: "light",
        dark: "dark",
      },
      defaultTheme: "light",
      attributeName: "data-theme",
    }),
  ],
  parameters: {
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/i,
      },
    },
    viewport: {
      options: {
        desktop: {
          name: "Desktop",
          styles: { width: "1280px", height: "720px" },
          type: "desktop",
        },
        tablet: {
          name: "Tablet landscape",
          styles: { width: "1024px", height: "640px" },
          type: "tablet",
        },
        mobile: {
          name: "Mobile",
          styles: { width: "320px", height: "900px" },
          type: "mobile",
        },
      },
    },
  },
};

export default preview;
