import Layout from "~/app/layout.svelte";
import { reset, set } from "~stories/mocks/inertia_svelte";

type Options = {
  url: string;
  variant?: "narrow" | "wide";
};

type Context = {
  args: {
    auth?: InertiaProps["auth"];
  };
};

export function withLayout({ url, variant }: Options) {
  return (_story: unknown, context: Context) => {
    const auth = context.args.auth;
    if (!auth) throw new Error("Page stories require deterministic authentication args.");

    reset();
    set({
      url,
      props: {
        auth,
        errors: {},
      },
    });

    return {
      Component: Layout,
      props: { variant },
    };
  };
}
