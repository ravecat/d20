<script lang="ts">
  import GameCollection from "./game-collection.svelte";
  import type { GameCatalogEntry } from "~/shared/types/game";

  type Props = InertiaProps<{
    playableGames: GameCatalogEntry[];
    games: GameCatalogEntry[];
    favorites?: number[];
  }>;

  const { playableGames, games, favorites = [] }: Props = $props();
</script>

<div class="home-page">
  <div class="home-shell">
    <h1 class="visually-hidden">Games</h1>
    <GameCollection games={playableGames} variant="compact" {favorites}>
      {#snippet header()}Playable{/snippet}
    </GameCollection>
    <GameCollection {games} {favorites}>
      {#snippet header()}Hot (<a href="https://boardgamegeek.com/hotness">by BGG</a>){/snippet}
    </GameCollection>
  </div>
</div>

<style>
  .home-page {
    background: var(--color-base-100);
    color: var(--color-base-content);
  }

  .home-shell {
    box-sizing: border-box;
    inline-size: 100%;
    max-inline-size: 46.25rem;
    margin-inline: auto;
    padding-block: 0.6667rem;
    padding-inline: 1rem;
  }

  .visually-hidden {
    position: absolute;
    inline-size: 1px;
    block-size: 1px;
    margin: -1px;
    padding: 0;
    overflow: hidden;
    border: 0;
    clip-path: inset(50%);
  }

  .home-shell > :global(.home-section + .home-section) {
    margin-block-start: 0.6667rem;
  }
</style>
