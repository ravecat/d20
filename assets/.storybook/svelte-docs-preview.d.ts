// Storybook exposes this preview entry point without a declaration file.
declare module "@storybook/svelte/entry-preview-docs" {
  import type { Preview } from "@storybook/svelte";

  export const decorators: NonNullable<Preview["decorators"]>;
}
