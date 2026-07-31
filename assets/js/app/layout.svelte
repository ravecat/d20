<script lang="ts">
  import type { Snippet } from "svelte";
  import { Footer, Header } from "~/shared/components";
  import { Workspace } from "~/widgets/workspace";

  type Variant = "default" | "narrow";

  type Props = {
    children?: Snippet;
    variant?: Variant;
  };

  const { children, variant = "default" }: Props = $props();
</script>

<div class="layout">
  <Workspace>
    <Header {variant} />
    <main class="layout__content" scroll-region tabindex="-1">
      {@render children?.()}
    </main>
    <Footer {variant} />
  </Workspace>
</div>

<style>
  .layout {
    display: grid;
    grid-template-rows: auto minmax(0, 1fr) auto;
    block-size: 100dvh;
    overflow: hidden;
    background: var(--color-base-100);
  }

  .layout__content {
    min-block-size: 0;
    overflow-y: auto;
    overscroll-behavior: contain;
    scrollbar-gutter: stable both-edges;
  }

  .layout__content:focus-visible {
    outline: 2px solid color-mix(in oklab, var(--color-base-content) 40%, transparent);
    outline-offset: -2px;
  }

  @supports (
    (animation-timeline: scroll()) and (animation-range: 0% 100%) and
      (scroll-timeline: --app-shell-scroll block) and (timeline-scope: --app-shell-scroll)
  ) {
    .layout {
      timeline-scope: --app-shell-scroll;
    }

    .layout__content {
      scroll-timeline: --app-shell-scroll block;
    }
  }
</style>
