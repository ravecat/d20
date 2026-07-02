<script lang="ts">
  import type {
    FormComponentProps,
    FormComponentSlotProps,
    FormDataConvertible,
  } from "@inertiajs/core";
  import type { Snippet } from "svelte";
  import inertiaMock from "./inertia";

  type FormFields = Record<string, FormDataConvertible>;
  type SlotProps = FormComponentSlotProps<FormFields>;

  type Props = {
    action?: FormComponentProps["action"];
    method?: FormComponentProps["method"];
    disableWhileProcessing?: boolean;
    class?: string;
    children?: Snippet<[SlotProps]>;
  };

  type HtmlFormMethod = "get" | "post" | "dialog";

  const {
    action = "",
    method = "get",
    disableWhileProcessing: _disableWhileProcessing = false,
    children,
    ...rest
  }: Props = $props();
  let formElement: HTMLFormElement;

  const errors: SlotProps["errors"] = {};
  const processing = false;
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
    submit,
    defaults: () => undefined,
    reset: () => undefined,
    getData,
    getFormData,
    validating: false,
    valid: () => false,
    invalid: (field) => field in errors,
    validate: () => undefined,
    touch: () => undefined,
    touched: () => false,
    validator: () => ({}) as ReturnType<SlotProps["validator"]>,
  });

  function submit() {
    inertiaMock.formSubmit({
      action: actionUrl(action),
      method: formMethod(action, method),
      data: getData(),
    });
  }

  function handleSubmit(event: SubmitEvent) {
    event.preventDefault();
    submit();
  }

  function getFormData() {
    return new FormData(formElement);
  }

  function getData() {
    const data: Record<string, FormDataConvertible | FormDataConvertible[]> = {};

    for (const [key, value] of getFormData()) {
      const current = data[key];

      if (current === undefined) {
        data[key] = value;
      } else if (Array.isArray(current)) {
        current.push(value);
      } else {
        data[key] = [current, value];
      }
    }

    return data as Record<string, FormDataConvertible>;
  }

  function actionUrl(action: FormComponentProps["action"]) {
    return typeof action === "string" ? action : (action?.url ?? "");
  }

  function formMethod(action: FormComponentProps["action"], method: FormComponentProps["method"]) {
    return (
      typeof action === "string" ? (method ?? "get") : (action?.method ?? method ?? "get")
    ).toLowerCase();
  }

  function htmlFormMethod(
    action: FormComponentProps["action"],
    method: FormComponentProps["method"],
  ): HtmlFormMethod {
    const normalized = formMethod(action, method);

    if (normalized === "post" || normalized === "dialog") {
      return normalized;
    }

    return "get";
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
