<script lang="ts">
  import {
    type FormComponentProps,
    type VisitOptions,
    type FormComponentSlotProps,
    type FormDataConvertible,
    formDataToObject,
  } from "@inertiajs/core";
  import type { Snippet } from "svelte";
  import inertiaMock from "./inertia";

  type FormFields = Record<string, FormDataConvertible>;
  type SlotProps = FormComponentSlotProps<FormFields>;

  type Props = {
    action?: FormComponentProps["action"];
    method?: FormComponentProps["method"];
    errorBag?: FormComponentProps["errorBag"];
    disableWhileProcessing?: boolean;
    options?: VisitOptions;
    onBefore?: FormComponentProps["onBefore"];
    onStart?: FormComponentProps["onStart"];
    onFinish?: FormComponentProps["onFinish"];
    onError?: FormComponentProps["onError"];
    onSuccess?: FormComponentProps["onSuccess"];
    class?: string;
    children?: Snippet<[SlotProps]>;
  };

  type HtmlFormMethod = "get" | "post" | "dialog";

  const {
    action = "",
    method = "get",
    errorBag = null,
    disableWhileProcessing: _disableWhileProcessing = false,
    options,
    onBefore,
    onStart,
    onFinish,
    onError,
    onSuccess,
    children,
    ...rest
  }: Props = $props();
  let formElement: HTMLFormElement;

  let errors = $state<SlotProps["errors"]>({});
  let processing = $state(false);
  let wasSuccessful = $state(false);
  const responder = {
    cancel() {
      processing = false;
      onFinish?.({} as never);
    },
    networkError() {
      options?.onNetworkError?.(new Error("Connection lost"));
      processing = false;
      onFinish?.({} as never);
    },
    error(nextErrors: Record<string, string>) {
      errors = nextErrors;
      processing = false;
      onError?.(nextErrors);
      onFinish?.({} as never);
    },
    success() {
      errors = {};
      processing = false;
      wasSuccessful = true;
      onSuccess?.(inertiaMock.page);
      onFinish?.({} as never);
    },
  };
  const slotProps = $derived<SlotProps>({
    errors,
    hasErrors: Object.keys(errors).length > 0,
    processing,
    progress: null,
    wasSuccessful,
    recentlySuccessful: wasSuccessful,
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
    if (onBefore?.({} as never) === false) return;
    processing = true;
    wasSuccessful = false;
    onStart?.({} as never);
    inertiaMock.submitForm(responder, {
      action: actionUrl(action),
      method: formMethod(action, method),
      data: getData(),
      ...(errorBag ? { errorBag } : {}),
      ...(options ? { options } : {}),
    });
  }

  function handleSubmit(event: SubmitEvent) {
    event.preventDefault();
    submit();
  }

  $effect(() => {
    return inertiaMock.registerForm(responder);
  });

  function getFormData() {
    return new FormData(formElement);
  }

  function getData() {
    return formDataToObject(getFormData());
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
