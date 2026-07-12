<script lang="ts">
  type Props = {
    compact?: boolean;
  };

  const { compact = false }: Props = $props();
</script>

<svg
  class={{
    d20: true,
    "d20--compact": compact,
  }}
  viewBox="45.5 25.5 269 309"
  aria-hidden="true"
>
  <path class="d20__faces" d="M180 29 L311 101 L311 258 L180 331 L49 258 L49 101 Z" />
  <path class="d20__outer-edges" d="M180 29 L311 101 L311 258 L180 331 L49 258 L49 101 Z" />
  <path
    class="d20__inner-edges"
    d="M180 29 L180 72 M49 101 L180 72 M311 101 L180 72 M180 72 L91 234 M180 72 L270 234 M91 234 L270 234 M49 101 L91 234 M311 101 L270 234 M49 258 L91 234 M311 258 L270 234 M91 234 L180 331 M270 234 L180 331"
  />
</svg>

<style>
  .d20 {
    inline-size: 2.612rem;
    block-size: 3rem;
    flex: none;
    overflow: visible;
    color: currentColor;
    --d20-face-color: color-mix(in oklab, currentColor 78%, white);
    --d20-edge-color: color-mix(in oklab, currentColor 5%, white);
    transition:
      inline-size 180ms ease,
      block-size 180ms ease;
  }

  .d20--compact {
    inline-size: 1.742rem;
    block-size: 2rem;
  }

  .d20__faces {
    fill: var(--d20-face-color);
    stroke: none;
  }

  .d20__outer-edges,
  .d20__inner-edges {
    fill: none;
    stroke: var(--d20-edge-color);
    stroke-linejoin: round;
  }

  .d20__outer-edges {
    stroke-width: 8.4;
    stroke-linecap: round;
  }

  .d20__inner-edges {
    stroke-width: 12.6;
    stroke-linecap: butt;
  }

  @media (max-width: 34rem) {
    .d20 {
      inline-size: 2.177rem;
      block-size: 2.5rem;
    }

    .d20--compact {
      inline-size: 1.742rem;
      block-size: 2rem;
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .d20 {
      transition: none;
    }
  }
</style>
