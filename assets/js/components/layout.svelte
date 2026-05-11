<script lang="ts">
  import type { Snippet } from "svelte";
  import Header from "~components/header.svelte";

  const { children }: { children?: Snippet } = $props();
</script>

<div class="layout">
  <Header />
  {@render children?.()}
</div>

<style>
  .layout {
    display: grid;
    grid-template-rows: auto minmax(0, 1fr);
    min-height: 100svh;
  }
</style>
