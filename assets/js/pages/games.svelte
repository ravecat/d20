<script lang="ts">
  import type { ModuleEntry } from "~types/module";

  type Props = InertiaProps<{
    modules: ModuleEntry[];
  }>;

  const { modules }: Props = $props();
</script>

<main class="min-h-screen bg-base-100 text-base-content">
  <section class="mx-auto min-h-screen w-full max-w-7xl px-5 py-6 sm:px-6 lg:px-8">
    {#if modules.length > 0}
      <div class="grid w-full grid-cols-[repeat(auto-fill,minmax(min(12.8rem,100%),1fr))] gap-6">
        {#each modules as module (module.id)}
          <a
            class="grid aspect-[205/87] w-full place-items-center rounded-sm border border-base-300 bg-white px-5 text-center text-sm font-semibold transition-colors hover:border-base-content/30 hover:bg-base-200 focus:outline-none focus:ring-2 focus:ring-base-content/40 focus:ring-offset-2 focus:ring-offset-base-100"
            href={`/games/${module.id}`}
          >
            <span class="min-w-0 break-words">{module.title}</span>
          </a>
        {/each}
      </div>
    {:else}
      <div class="grid min-h-[50vh] place-items-center text-sm text-base-content/60">No games</div>
    {/if}
  </section>
</main>
