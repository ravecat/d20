import "@sjsf/form/fields/extra/enum-include";
import "@sjsf/basic-theme/extra-widgets/radio-include";

import { createFormValidator as validator } from "@sjsf/ajv8-validator";
import { theme as basicTheme } from "@sjsf/basic-theme";
import type { Config } from "@sjsf/form";
import { createFormIdBuilder } from "@sjsf/form/id-builders/modern";
import { chain, fromFactories } from "@sjsf/form/lib/resolver";
import { createFormMerger as merger } from "@sjsf/form/mergers/modern";
import { resolver } from "@sjsf/form/resolvers/compat";
import { translation } from "@sjsf/form/translations/en";

const enumRadioTheme = fromFactories({
  selectWidget: (config: Config) =>
    Array.isArray(config.schema.enum) ? basicTheme("radioWidget", config) : undefined,
});
const theme = chain(enumRadioTheme, basicTheme);

export default { idBuilder: createFormIdBuilder, merger, resolver, theme, translation, validator };
