<script module lang="ts">
  export type InlineNotificationKind = "info" | "warning" | "error";
</script>

<script lang="ts">
  import type { Snippet } from "svelte";

  let { children, kind }: { children: Snippet; kind: InlineNotificationKind } = $props();

  const severityLabel = $derived(
    kind === "info" ? "Information" : kind === "warning" ? "Warning" : "Error",
  );
  const symbol = $derived(kind === "info" ? "i" : kind === "warning" ? "!" : "×");
</script>

<aside
  class="inline-notification"
  class:inline-notification--info={kind === "info"}
  class:inline-notification--warning={kind === "warning"}
  class:inline-notification--error={kind === "error"}
  role={kind === "error" ? "alert" : "status"}
  aria-atomic="true"
>
  <div class="inline-notification__content">
    {@render children()}
  </div>

  <span class="inline-notification__icon" aria-label={severityLabel}>{symbol}</span>
</aside>

<style>
  .inline-notification {
    --inline-notification-accent: var(--color-info);

    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    align-items: start;
    gap: 0.4rem;
    border: var(--border) solid var(--inline-notification-accent);
    border-radius: var(--radius-field);
    /* Direct theme tokens let forced-dark extensions identify surface colors. */
    background: color-mix(in oklab, var(--color-info) 10%, var(--color-base-200));
    padding: 0.8rem 0.6rem;
    color: var(--color-base-content);
    font-size: 0.85rem;
    line-height: 1.45;
  }

  .inline-notification--warning {
    --inline-notification-accent: var(--color-warning);

    background: color-mix(in oklab, var(--color-warning) 10%, var(--color-base-200));
  }

  .inline-notification--error {
    --inline-notification-accent: var(--color-error);

    background: color-mix(in oklab, var(--color-error) 10%, var(--color-base-200));
  }

  .inline-notification__content {
    min-inline-size: 0;
    text-wrap: pretty;
  }

  .inline-notification__icon {
    display: grid;
    inline-size: 1.55rem;
    block-size: 1.55rem;
    flex: none;
    place-items: center;
    border: 0.125rem solid currentColor;
    border-radius: 50%;
    color: var(--inline-notification-accent);
    font-size: 0.88rem;
    font-weight: 900;
    line-height: 1;
  }

  :global(.inline-notification__content a) {
    color: var(--inline-notification-accent);
    font-weight: 700;
    white-space: nowrap;
    text-wrap: nowrap;
  }
</style>
