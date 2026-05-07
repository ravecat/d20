<script lang="ts">
  // biome-ignore lint/correctness/noUnusedImports: Biome does not track Svelte component usage in markup.
  import Frame from "~components/module_frame.svelte";
  import type { ModuleEntry } from "~types/module";

  type Props = InertiaProps<{
    modules: ModuleEntry[];
  }>;

  const { modules }: Props = $props();
</script>

<main class="min-h-screen bg-base-100 text-base-content">
  <section class="mx-auto w-full max-w-7xl px-5 py-6 sm:px-6 lg:px-8">
    {#if modules.length > 0}
      <div class="grid grid-cols-[repeat(auto-fill,minmax(min(18rem,100%),1fr))] gap-5">
        {#each modules as module (module.id)}
          <article
            class="group relative grid aspect-square min-w-0 grid-rows-[80%_20%] overflow-hidden rounded-sm border border-base-300 bg-base-200 transition-colors hover:border-base-content/30 hover:bg-base-300"
          >
            <div class="min-h-0 bg-base-300">
              <Frame {module} />
            </div>

            <div class="grid min-h-0 min-w-0 content-center px-3 py-2">
              <h2 class="truncate text-sm font-semibold leading-tight">{module.title}</h2>
            </div>
          </article>
        {/each}
      </div>
    {:else}
      <div class="grid min-h-[50vh] place-items-center text-sm text-base-content/60">No games</div>
    {/if}
  </section>
</main>
