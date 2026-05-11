<script lang="ts">
  import { inertia, useForm } from "@inertiajs/svelte";
  import Frame from "~components/module_frame.svelte";
  import type { GameDetails, GameSession } from "~types/game";
  import type { ModuleEntry } from "~types/module";

  type Props = InertiaProps<{
    game: GameDetails;
    module: ModuleEntry;
    session: GameSession | null;
  }>;

  const { game, module, session }: Props = $props();
  const startSessionForm = useForm<Record<string, string>>({});

  const handleStartSession = () => {
    if ($startSessionForm.processing) {
      $startSessionForm.cancel();
      return;
    }

    $startSessionForm.clearErrors();
    $startSessionForm.post(`/games/${game.slug}/sessions`);
  };
</script>

<main class="bg-base-100 text-base-content">
  <section class="mx-auto grid w-full max-w-[46.25rem] gap-6 px-6 py-6 max-[34rem]:px-4">
    <article class="min-w-0">
      <a
        class="rounded-sm px-2 py-1 text-sm text-base-content/70 transition-colors hover:bg-base-200 hover:text-base-content focus:outline-none focus:ring-2 focus:ring-base-content/40"
        href="/games"
        use:inertia={{ href: "/games" }}
      >
        Games
      </a>

      <div class="mt-5 flex flex-wrap items-end justify-between gap-4">
        <div class="min-w-0">
          <h1 class="text-3xl font-semibold tracking-normal">{game.name}</h1>
          {#if game.yearPublished}
            <p class="mt-1 text-sm text-base-content/60">{game.yearPublished}</p>
          {/if}
        </div>
      </div>

      <p class="mt-4 max-w-3xl text-sm leading-6 text-base-content/75">{game.description}</p>

      {#if session && module.bootstrap}
        <section class="mt-6 h-[34rem] min-h-0 overflow-hidden rounded-sm border border-base-300">
          <Frame {module} />
        </section>
      {:else if session}
        <p class="mt-6 text-sm text-base-content/70">Waiting for players</p>
      {:else}
        <div class="mt-8 border-t border-base-300 pt-5">
          <button
            class="inline-flex min-h-10 min-w-28 items-center justify-center gap-2 rounded-sm border border-base-content bg-base-content px-5 py-2 text-sm font-medium text-base-100 transition-colors hover:bg-base-content/85 focus:outline-none focus:ring-2 focus:ring-base-content/40"
            type="button"
            aria-busy={$startSessionForm.processing}
            onclick={handleStartSession}
          >
            {#if $startSessionForm.processing}
              <span
                class="size-3.5 animate-spin rounded-full border-2 border-base-100/35 border-t-base-100"
                aria-hidden="true"
              ></span>
              Cancel
            {:else}
              Start
            {/if}
          </button>
        </div>
      {/if}

      {#if $startSessionForm.errors.startSession}
        <p class="mt-3 text-sm text-error">{$startSessionForm.errors.startSession}</p>
      {/if}
    </article>
  </section>
</main>
