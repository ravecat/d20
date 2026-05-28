<script lang="ts">
  import { inertia } from "@inertiajs/svelte";
  import type { GameMetadata } from "~types/game";

  type Props = InertiaProps<{
    games: GameMetadata[];
  }>;

  const { games }: Props = $props();
</script>

<main class="bg-base-100 text-base-content">
  <section class="mx-auto w-full max-w-185 px-6 py-6 max-[34rem]:px-4">
    {#if games.length > 0}
      <div class="grid w-full grid-cols-[repeat(auto-fill,minmax(min(12.8rem,100%),1fr))] gap-6">
        {#each games as game (game.slug)}
          <a
            class="grid aspect-205/87 w-full place-items-center rounded-sm border border-accent bg-accent px-5 text-center text-sm font-semibold text-accent-content shadow-sm transition-[background-color,border-color,color,box-shadow] duration-200 hover:border-[oklch(88%_0.004_286.32)] hover:bg-[oklch(88%_0.004_286.32)] hover:!text-accent-content hover:shadow-md focus:outline-none focus:ring-2 focus:ring-base-content/30 focus:ring-offset-2 focus:ring-offset-base-100"
            href={`/games/${game.slug}`}
            use:inertia={{ href: `/games/${game.slug}` }}
          >
            <span class="min-w-0 wrap-break-words">{game.name}</span>
          </a>
        {/each}
      </div>
    {:else}
      <div class="grid min-h-[50vh] place-items-center text-sm text-base-content/60">No games</div>
    {/if}
  </section>
</main>
