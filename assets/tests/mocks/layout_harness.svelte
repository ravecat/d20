<script lang="ts">
  import Layout from "~/app/layout.svelte";

  type Variant = "default" | "narrow";

  let variant = $state<Variant>("default");
  let pageName = $state("initial");

  export function navigate(nextPage: string, nextVariant: Variant) {
    pageName = nextPage;
    variant = nextVariant;
  }
</script>

<Layout {variant}>
  <p class="page" data-page={pageName}>{pageName}</p>
</Layout>

<style>
  .page {
    min-block-size: 200dvh;
  }
</style>
