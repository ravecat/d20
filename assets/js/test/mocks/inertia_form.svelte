<script lang="ts">
  import type { FormDataConvertible } from "@inertiajs/core";
  import type { Snippet } from "svelte";
  import inertiaMock from "./inertia";

  type SlotProps = {
    errors: Record<string, string>;
    hasErrors: boolean;
    processing: boolean;
    progress: null;
    wasSuccessful: boolean;
    recentlySuccessful: boolean;
    isDirty: boolean;
    clearErrors: (...fields: string[]) => void;
    resetAndClearErrors: (...fields: string[]) => void;
    setError: (fieldOrFields: string | Record<string, string>, value?: string) => void;
    submit: (submitter?: HTMLElement | null) => void;
    defaults: () => void;
    reset: (...fields: string[]) => void;
    getData: (submitter?: HTMLElement | null) => Record<string, FormDataConvertible>;
    getFormData: (submitter?: HTMLElement | null) => FormData;
  };

  type Props = {
    action?: string;
    method?: string;
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

  const errors: Record<string, string> = {};
  const processing = false;
  const slotProps = $derived({
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
  });

  function submit() {
    inertiaMock.formSubmit({
      action,
      method: method.toLowerCase(),
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

  function htmlFormMethod(method: string): HtmlFormMethod {
    const normalized = method.toLowerCase();

    if (normalized === "post" || normalized === "dialog") {
      return normalized;
    }

    return "get";
  }
</script>

<form
  bind:this={formElement}
  {action}
  method={htmlFormMethod(method)}
  onsubmit={handleSubmit}
  {...rest}
>
  {#if children}
    {@render children(slotProps)}
  {/if}
</form>
