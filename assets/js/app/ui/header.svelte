<script lang="ts">
  import type { FormComponentSlotProps } from "@inertiajs/core";
  import { Form, inertia, usePage } from "@inertiajs/svelte";
  import { useSelector } from "@xstate/store-svelte";
  import { AuthDialog } from "~/shared/components";
  import { auth } from "~/shared/stores";

  type Variant = "narrow" | "wide";
  type FormSlotProps = FormComponentSlotProps<Record<string, string>>;

  type Props = {
    overlay?: boolean;
    variant?: Variant;
  };

  const { overlay = false, variant = "narrow" }: Props = $props();

  const page = usePage();
  const open = useSelector(auth, ({ context }) => context.open);

  $effect(() => {
    const prompt = page.props.auth.prompt;

    if (prompt) auth.trigger.open({ prompt });
  });
</script>

<header
  class={{
    header: true,
    "header--wide": variant === "wide",
    "header--overlay": overlay,
  }}
>
  <div class="header__inner">
    <a class="brand" href="/" use:inertia={{ href: "/" }}>
      <span class="brand__mark" aria-hidden="true"></span>
      <span class="brand__label">D20</span>
    </a>

    {#if page.props.auth.authenticated}
      <nav class="header__actions" aria-label="Account">
        <a
          class="header__account-link"
          href="/users/settings"
          use:inertia={{ href: "/users/settings" }}
        >
          Settings
        </a>
        <Form class="header__logout-form" method="delete" action="/users/log-out">
          {#snippet children({ processing }: FormSlotProps)}
            <button class="header__account-link" type="submit" disabled={processing}>
              {processing ? "Logging out..." : "Log out"}
            </button>
          {/snippet}
        </Form>
      </nav>
    {:else}
      <nav class="header__actions" aria-label="Account">
        <button class="header__register" type="button" onclick={() => auth.trigger.open()}>
          Register
        </button>
      </nav>
    {/if}
  </div>

  {#if $open}
    <AuthDialog />
  {/if}
</header>

<style>
  .header {
    position: sticky;
    inset-block-start: 0;
    z-index: 20;
    width: 100%;
    overflow: hidden;
    scrollbar-gutter: stable both-edges;
  }

  .header--overlay {
    position: absolute;
    inset-block-start: 0;
    inset-inline: 0;
    z-index: 10;
    background: transparent;
    pointer-events: none;
  }

  .header__inner {
    display: flex;
    box-sizing: border-box;
    inline-size: 100%;
    max-inline-size: 46.25rem;
    margin-inline: auto;
    padding-inline: 1rem;
    padding-block: 1rem;
    align-items: center;
    gap: 1.5rem;
  }

  .header__actions {
    display: flex;
    margin-inline-start: auto;
    align-items: center;
  }

  .header__register {
    min-block-size: 2.5rem;
    border: 0;
    border-radius: var(--radius-field);
    background: var(--color-primary);
    padding-inline: 1rem;
    color: var(--color-primary-content);
    font: inherit;
    font-size: 0.8rem;
    font-weight: 700;
    cursor: pointer;
  }

  .header__account-link {
    border: 0;
    background: transparent;
    padding: 0.45rem 0.6rem;
    color: var(--color-base-content);
    font: inherit;
    font-size: 0.8rem;
    font-weight: 700;
    text-decoration: none;
    cursor: pointer;
  }

  .header__account-link:disabled {
    cursor: wait;
    opacity: 0.68;
  }

  :global(.header__logout-form) {
    display: contents;
  }

  .header--wide .header__inner {
    max-inline-size: 64rem;
    padding-inline: 0;
  }

  .brand {
    display: inline-flex;
    align-items: center;
    gap: 0.5625rem;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    transition: color 160ms ease;
  }

  .brand__mark {
    display: block;
    inline-size: 2.612rem;
    block-size: 3rem;
    flex: none;
    background: url("/images/d20.svg") center / contain no-repeat;
  }

  .brand__label {
    font-size: 0.875rem;
    font-weight: 600;
    line-height: 1;
  }

  .header--overlay .brand,
  .header--overlay .header__actions {
    pointer-events: auto;
  }

  .brand:focus-visible {
    outline: none;
  }

  .brand:focus-visible .brand__label {
    text-decoration-line: underline;
    text-decoration-thickness: 0.125rem;
    text-underline-offset: 0.35em;
  }

  .header__register:focus-visible {
    outline: 0.1875rem solid var(--color-primary);
    outline-offset: 0.1875rem;
  }

  @media (max-width: 34rem) {
    .header__inner {
      gap: 1rem;
    }

    .brand__mark {
      inline-size: 2.177rem;
      block-size: 2.5rem;
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .brand {
      transition: none;
    }
  }

  @supports (
    (animation-timeline: scroll()) and (animation-range: 0% 100%) and
      (scroll-timeline: --app-shell-scroll block) and (timeline-scope: --app-shell-scroll)
  ) {
    .header__inner {
      animation: compact-header-inner auto linear both;
      animation-timeline: --app-shell-scroll;
      animation-range: 0px 24px;
    }

    .brand {
      animation: compact-header-brand auto linear both;
      animation-timeline: --app-shell-scroll;
      animation-range: 0px 24px;
    }

    .brand__mark {
      animation: compact-header-mark auto linear both;
      animation-timeline: --app-shell-scroll;
      animation-range: 0px 24px;
    }

    .brand__label {
      animation: compact-header-label auto linear both;
      animation-timeline: --app-shell-scroll;
      animation-range: 0px 24px;
    }

    .header__register {
      animation: compact-header-register auto linear both;
      animation-timeline: --app-shell-scroll;
      animation-range: 0px 24px;
    }

    @media (prefers-reduced-motion: reduce) {
      .header__inner,
      .brand,
      .brand__mark,
      .brand__label,
      .header__register {
        animation: none;
      }
    }
  }

  @keyframes compact-header-inner {
    to {
      padding-block: 0.5rem;
    }
  }

  @keyframes compact-header-brand {
    to {
      gap: 0.4rem;
    }
  }

  @keyframes compact-header-mark {
    to {
      inline-size: 1.742rem;
      block-size: 2rem;
    }
  }

  @keyframes compact-header-label {
    to {
      font-size: 0.75rem;
      letter-spacing: 0.12em;
    }
  }

  @keyframes compact-header-register {
    to {
      min-block-size: 2rem;
    }
  }
</style>
