<script lang="ts">
  import type { Snippet } from "svelte";

  type Props = {
    children: Snippet;
  };

  const { children }: Props = $props();

  function preventNavigation(node: HTMLElement) {
    const preventLinkNavigation = (event: MouseEvent) => {
      if (event.target instanceof Element && event.target.closest("a")) event.preventDefault();
    };

    node.addEventListener("click", preventLinkNavigation);

    return {
      destroy: () => node.removeEventListener("click", preventLinkNavigation),
    };
  }
</script>

<div use:preventNavigation>
  {@render children()}
</div>
