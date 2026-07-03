<script lang="ts">
  import type { Snippet } from "svelte";
  import Header from "~components/header.svelte";

  type Variant = "default" | "catalog";

  type Props = {
    children?: Snippet;
    variant?: Variant;
  };

  const { children, variant = "default" }: Props = $props();
</script>

<div class="layout">
  <Header {variant} />
  {@render children?.()}
</div>

<style>
  .layout {
    display: grid;
    grid-template-rows: auto minmax(0, 1fr);
    min-height: 100svh;
  }
</style>
