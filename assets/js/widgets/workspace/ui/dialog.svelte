<script lang="ts">
  import type { Snippet } from "svelte";
  import type { Attachment } from "svelte/attachments";

  interface Props {
    children: Snippet<[{ fullscreen: boolean; toggle: () => Promise<void> }]>;
    label: string;
  }

  const { children, label }: Props = $props();

  let fullscreenElement: HTMLDivElement | undefined;
  let fullscreen = $state(false);

  function synchronizeFullscreen() {
    fullscreen = document.fullscreenElement === fullscreenElement;
  }

  async function toggle() {
    if (!fullscreenElement) return;

    try {
      if (document.fullscreenElement === fullscreenElement) {
        await document.exitFullscreen();
      } else {
        await fullscreenElement.requestFullscreen({ navigationUI: "hide" });
      }
    } catch {
      return;
    }
  }

  const show: Attachment<HTMLDialogElement> = (dialog) => {
    dialog.show();

    return () => {
      if (dialog.open) dialog.close();
    };
  };

  const captureFullscreenElement: Attachment<HTMLDivElement> = (element) => {
    fullscreenElement = element;

    return () => {
      if (fullscreenElement === element) fullscreenElement = undefined;
    };
  };
</script>

<svelte:document onfullscreenchange={synchronizeFullscreen} />

<dialog {@attach show} class="dialog" aria-label={label}>
  <div {@attach captureFullscreenElement} class="dialog__surface">
    {@render children({ fullscreen, toggle })}
  </div>
</dialog>

<style>
  .dialog {
    position: relative;
    z-index: 1000;
    inset: auto;
    box-sizing: border-box;
    inline-size: 100%;
    min-inline-size: 0;
    block-size: 100%;
    min-block-size: 0;
    max-inline-size: none;
    max-block-size: none;
    margin: 0;
    overflow: visible;
    border: 0;
    background: transparent;
    padding: 0;
    color: inherit;
  }

  .dialog__surface {
    position: relative;
    box-sizing: border-box;
    inline-size: 100%;
    block-size: 100%;
    overflow: auto;
    border: 1px solid color-mix(in oklab, var(--color-base-content) 16%, transparent);
    border-radius: var(--radius-sm);
    background: var(--color-base-100);
    box-shadow: var(--dialog-surface-shadow, 0 1.5rem 4rem rgb(0 0 0 / 0.34));
  }

  .dialog__surface:fullscreen {
    border: 0;
    border-radius: 0;
  }
</style>
