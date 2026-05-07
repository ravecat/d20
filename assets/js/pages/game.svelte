<script lang="ts">
  import Frame from "~components/module_frame.svelte";
  import type { ModuleEntry } from "~types/module";

  type Props = InertiaProps<{
    module: ModuleEntry;
  }>;

  const { module }: Props = $props();
</script>

<main class="grid h-screen min-h-0 grid-rows-[auto_1fr] bg-base-100 text-base-content">
  <header
    class="grid min-w-0 grid-cols-[auto_1fr] items-center gap-3 border-b border-base-300 px-4 py-3"
  >
    <a
      class="rounded-sm px-2 py-1 text-sm text-base-content/70 transition-colors hover:bg-base-200 hover:text-base-content focus:outline-none focus:ring-2 focus:ring-base-content/40"
      href="/games"
    >
      Games
    </a>
    <h1 class="truncate text-sm font-semibold leading-tight">{module.title}</h1>
  </header>

  <section class="min-h-0">
    <Frame {module} />
  </section>
</main>
