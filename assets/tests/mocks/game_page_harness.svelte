<script lang="ts">
  import { untrack } from "svelte";
  import { GamePage } from "~/pages/game";
  import type { Attrs, GameMetadata, SessionDescriptor } from "~/shared/types";

  interface GamePageProps {
    slug: string;
    canLaunchGame: boolean;
    game: GameMetadata;
    attrs?: Attrs;
    session?: SessionDescriptor | null;
  }

  interface Props {
    pageProps: GamePageProps;
  }

  const { pageProps }: Props = $props();
  const inertiaPageProps = untrack(() => pageProps as InertiaProps<GamePageProps>);
</script>

<GamePage {...inertiaPageProps} />
