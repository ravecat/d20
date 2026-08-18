<script lang="ts">
  import type {
    FormComponentProps,
    FormComponentSlotProps,
    FormDataConvertible,
  } from "@inertiajs/core";
  import type { Snippet } from "svelte";

  type FormFields = Record<string, FormDataConvertible>;
  type SlotProps = FormComponentSlotProps<FormFields>;

  type Props = {
    action?: FormComponentProps["action"];
    method?: FormComponentProps["method"];
    disableWhileProcessing?: boolean;
    class?: string;
    children?: Snippet<[SlotProps]>;
  };

  type HtmlFormMethod = "get" | "post";

  const {
    action = "",
    method = "get",
    disableWhileProcessing: _disableWhileProcessing = false,
    children,
    ...rest
  }: Props = $props();

  const slotProps: SlotProps = {
    errors: {},
    hasErrors: false,
    processing: false,
    progress: null,
    wasSuccessful: false,
    recentlySuccessful: false,
    isDirty: false,
    clearErrors: () => undefined,
    resetAndClearErrors: () => undefined,
    setError: () => undefined,
    submit: () => undefined,
    defaults: () => undefined,
    reset: () => undefined,
    getData: () => ({}),
    getFormData: () => new FormData(),
    validating: false,
    valid: () => false,
    invalid: () => false,
    validate: () => undefined,
    touch: () => undefined,
    touched: () => false,
    validator: () => ({}) as ReturnType<SlotProps["validator"]>,
  };

  function actionUrl(value: FormComponentProps["action"]) {
    return typeof value === "string" ? value : (value?.url ?? "");
  }

  function htmlFormMethod(
    value: FormComponentProps["action"],
    fallback: FormComponentProps["method"],
  ): HtmlFormMethod {
    const valueMethod = typeof value === "string" ? fallback : value?.method;
    return valueMethod?.toLowerCase() === "get" ? "get" : "post";
  }
</script>

<form
  action={actionUrl(action)}
  method={htmlFormMethod(action, method)}
  onsubmit={(event) => event.preventDefault()}
  {...rest}
>
  {#if children}
    {@render children(slotProps)}
  {/if}
</form>
