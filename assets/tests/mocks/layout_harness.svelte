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
  <p data-page={pageName}>{pageName}</p>
</Layout>
