import "@sjsf/form/fields/extra/enum-include";

import { createFormValidator as validator } from "@sjsf/ajv8-validator";
import { theme } from "@sjsf/basic-theme";
import { createFormIdBuilder } from "@sjsf/form/id-builders/modern";
import { createFormMerger as merger } from "@sjsf/form/mergers/modern";
import { resolver } from "@sjsf/form/resolvers/compat";
import { translation } from "@sjsf/form/translations/en";

export default { idBuilder: createFormIdBuilder, merger, resolver, theme, translation, validator };
