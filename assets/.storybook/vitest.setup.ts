import * as docsAnnotations from "@storybook/addon-docs/preview";
import * as a11yAnnotations from "@storybook/addon-a11y/preview";
import * as themeAnnotations from "@storybook/addon-themes/preview";
import * as svelteDocsAnnotations from "@storybook/svelte/entry-preview-docs";
import { setProjectAnnotations } from "@storybook/svelte-vite";
import { afterEach, expect, inject } from "vitest";
import * as previewAnnotations from "./preview";

declare module "vitest" {
  interface ProvidedContext {
    visualGlobals: {
      theme: "light" | "dark";
      viewport: { value: "desktop" | "tablet" | "mobile" };
    };
  }
}

setProjectAnnotations([
  svelteDocsAnnotations,
  docsAnnotations,
  a11yAnnotations,
  themeAnnotations,
  previewAnnotations,
  { initialGlobals: inject("visualGlobals") },
]);

afterEach(async () => {
  await Promise.all(Array.from(document.fonts, (font) => font.load()));
  await expect(document.documentElement).toMatchScreenshot({
    // Allow the multi-frame stability check to finish under a full-suite workload.
    timeout: 15_000,
  });
});
