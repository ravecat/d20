<script lang="ts">
  import { Layout } from "~/shared/components";

  type Variant = "catalog" | "default";

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
