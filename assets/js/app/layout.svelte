<script lang="ts">
  import type { Snippet } from "svelte";
  import { Workspace } from "~/widgets/workspace";
  import { Footer, Header } from "./ui";

  type Variant = "narrow" | "wide";

  type Props = {
    children?: Snippet;
    variant?: Variant;
  };

  const { children, variant = "narrow" }: Props = $props();
</script>

<div class="layout">
  <Workspace>
    <Header {variant} />
    <main class="layout__content" tabindex="-1">
      {@render children?.()}
    </main>
    <Footer {variant} />
  </Workspace>
</div>

<style>
  :global(html) {
    scroll-padding-block-start: 3.75rem;
  }

  .layout {
    display: flex;
    flex-direction: column;
    box-sizing: border-box;
    min-block-size: 100dvh;
    padding-block-start: 3.75rem;
    background: var(--color-base-100);
  }

  @media (max-width: 34rem) {
    :global(html) {
      scroll-padding-block-start: 3.375rem;
    }

    .layout {
      padding-block-start: 3.375rem;
    }
  }

  .layout__content {
    flex: 1;
  }

  .layout__content:focus-visible {
    outline: 2px solid color-mix(in oklab, var(--color-base-content) 40%, transparent);
    outline-offset: -2px;
  }
</style>
