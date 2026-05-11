<script lang="ts">
  import type { Snippet } from "svelte";
  import Header from "~components/header.svelte";

  const { children }: { children?: Snippet } = $props();
</script>

<div class="cursor-layout">
  <Header overlay />
  {@render children?.()}
</div>

<style>
  .cursor-layout {
    position: relative;
    block-size: 100svh;
    overflow: hidden;
    background: var(--color-base-100);
    color: var(--color-base-content);
  }
</style>
