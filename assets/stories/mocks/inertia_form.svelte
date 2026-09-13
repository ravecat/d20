<script lang="ts">
  import { formDataToObject } from "@inertiajs/core";
  import { submitForm } from "./inertia_svelte";
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
    errorBag?: FormComponentProps["errorBag"];
    disableWhileProcessing?: boolean;
    options?: FormComponentProps["options"];
    onBefore?: FormComponentProps["onBefore"];
    onStart?: FormComponentProps["onStart"];
    onFinish?: FormComponentProps["onFinish"];
    onError?: FormComponentProps["onError"];
    class?: string;
    children?: Snippet<[SlotProps]>;
  };

  type HtmlFormMethod = "get" | "post";

  const {
    action = "",
    method = "get",
    errorBag: _errorBag,
    disableWhileProcessing: _disableWhileProcessing = false,
    children,
    options: _options,
    onBefore,
    onStart,
    onFinish,
    onError,
    ...rest
  }: Props = $props();

  let formElement: HTMLFormElement;
  let processing = $state(false);
  let errors = $state<Record<string, string>>({});
  const slotProps = $derived<SlotProps>({
    errors,
    hasErrors: Object.keys(errors).length > 0,
    processing,
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
  });

  async function handleSubmit(event: SubmitEvent) {
    event.preventDefault();
    if (onBefore?.({} as never) === false) return;
    processing = true;
    errors = {};
    onStart?.({} as never);
    try {
      const response = await submitForm({
        action: actionUrl(action),
        method: (typeof action === "string" ? method : action?.method) ?? "get",
        data: formDataToObject(new FormData(formElement)),
      });
      if (response?.errors) {
        errors = response.errors;
        onError?.(errors);
      }
    } finally {
      processing = false;
      onFinish?.({} as never);
    }
  }

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
  bind:this={formElement}
  action={actionUrl(action)}
  method={htmlFormMethod(action, method)}
  onsubmit={handleSubmit}
  {...rest}
>
  {#if children}
    {@render children(slotProps)}
  {/if}
</form>
