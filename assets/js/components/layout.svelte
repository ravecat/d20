<script lang="ts">
  import type { Snippet } from "svelte";
  import Footer from "~components/footer.svelte";
  import Header from "~components/header.svelte";

  type Variant = "default" | "catalog";

  type Props = {
    children?: Snippet;
    variant?: Variant;
  };

  const { children, variant = "default" }: Props = $props();
  let compactHeader = $state(false);

  function handleScroll(event: UIEvent) {
    const scrollRegion = event.currentTarget as HTMLElement;
    compactHeader = scrollRegion.scrollTop > 24;
  }
</script>

<div class="layout">
  <Header {variant} compact={compactHeader} />
  <main class="layout__content" scroll-region tabindex="-1" onscroll={handleScroll}>
    {@render children?.()}
  </main>
  <Footer {variant} />
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
    scrollbar-gutter: stable;
  }

  .layout__content:focus-visible {
    outline: 2px solid color-mix(in oklab, var(--color-base-content) 40%, transparent);
    outline-offset: -2px;
  }
</style>
