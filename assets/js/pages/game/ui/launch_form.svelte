<script lang="ts">
  import { router, usePage } from "@inertiajs/svelte";
  import { BasicForm, createForm, updateFieldErrorsByPath, type Schema } from "@sjsf/form";
  import type { SchemaObjectValue } from "@sjsf/form/core";
  import { onDestroy } from "svelte";
  import formDefaults from "~/shared/lib/form";

  type Props = {
    id: string;
    schema: Schema;
  };

  const { id, schema }: Props = $props();
  const page = usePage();
  let processing = $state(false);

  const form = createForm<SchemaObjectValue>({
    ...formDefaults,
    uiSchema: {
      "ui:globalOptions": {
        translations: { submit: "Play" },
      },
    },
    get schema() {
      return schema;
    },
    get disabled() {
      return processing;
    },
    onSubmit: submit,
  });

  onDestroy(() => {
    form.submission.abort();
    form.fieldsValidation.abort();
  });

  function submit(value: SchemaObjectValue) {
    router.post(`/games/${id}/sessions`, value, {
      errorBag: "session",
      onStart: () => {
        processing = true;
      },
      onError: (errors) => {
        for (const [name, message] of Object.entries(errors)) {
          if (name !== "session") {
            updateFieldErrorsByPath(form, [name], [message]);
          }
        }
      },
      onFinish: () => {
        processing = false;
      },
    });
  }
</script>

<BasicForm {form} novalidate />

{#if !processing && page.props.errors.session?.session}
  <p class="game-detail-activation__error">{page.props.errors.session.session}</p>
{/if}

<style>
  .game-detail-activation__error {
    margin: 0;
    color: var(--color-error);
    font-size: 0.8125rem;
    line-height: 1.4;
  }
</style>
