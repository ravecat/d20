<script lang="ts">
  import type { Snippet } from "svelte";

  const { children, compact = false }: { children?: Snippet; compact?: boolean } = $props();
</script>

<div class={{ frame: true, "frame--compact": compact }}>
  {@render children?.()}
</div>

<style>
  .frame {
    box-sizing: border-box;
    inline-size: 100%;
    max-inline-size: 46.25rem;
    margin-inline: auto;
    padding-block: 0.6667rem;
    padding-inline: 1rem;
  }

  .frame--compact {
    max-inline-size: calc(clamp(9.5rem, 42vw, 16rem) + 2rem);
  }
</style>
