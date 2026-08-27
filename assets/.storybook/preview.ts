import type { Preview } from "@storybook/svelte-vite";
import "../css/app.css";

const preview: Preview = {
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
  initialGlobals: {
    viewport: { value: "desktop" },
  },
};

export default preview;
