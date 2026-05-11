<script>
  import { cursors } from "~stores/cursor";

  let localCursor = $state(null);

  const remoteCursors = $derived($cursors.value ?? []);

  function handlePointerMove(event) {
    localCursor = {
      x: Math.round(event.offsetX),
      y: Math.round(event.offsetY),
    };

    cursors.move(localCursor);
  }

  function cursorColor(id) {
    let hash = 0;

    for (let index = 0; index < id.length; index += 1) {
      hash = (hash * 31 + id.charCodeAt(index)) >>> 0;
    }

    return `hsl(${hash % 360} 80% 50%)`;
  }
</script>

<svg class="cursors-page" onpointermove={handlePointerMove} role="presentation">
  {#if localCursor}
    <circle class="local-cursor" cx={localCursor.x} cy={localCursor.y} r="10" />
  {/if}

  {#each remoteCursors as cursor (cursor.id)}
    <circle
      class="remote-cursor"
      cx={cursor.x}
      cy={cursor.y}
      r="10"
      style={`--cursor-color: ${cursorColor(cursor.id)}`}
    />
  {/each}
</svg>

<style>
  .cursors-page {
    display: block;
    height: 100%;
    overflow: hidden;
    touch-action: none;
    width: 100%;
  }

  .remote-cursor {
    fill: var(--cursor-color);
    filter: drop-shadow(0 1px 2px rgb(0 0 0 / 0.35));
    opacity: 0.9;
    pointer-events: none;
  }

  .local-cursor {
    fill: #06b6d4;
    filter: drop-shadow(0 1px 2px rgb(0 0 0 / 0.35));
    opacity: 0.95;
    pointer-events: none;
  }
</style>
