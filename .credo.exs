# Credo configuration for D20.
#
# The gate runs `mix credo --strict` (see the `mix ci` alias). Findings fail
# unless a reviewed existing finding has an exact inline suppression.
# Suppressions must stay narrow and justified: blanket ignore rules are rejected
# by the backend quality gate specification.

%{
  configs: [
    %{
      name: "default",
      plugins: [{ExSlop, []}],
      checks: [
        # Recode (.recode.exs AliasExpansion/AliasOrder) owns alias rewriting
        # policy, so Credo's alias usage distance advice is disabled here.
        {Credo.Check.Design.AliasUsage, false},
        # D20 module documentation uses plain @moduledoc prose; ExSlop's
        # narrator-style doc check does not match this repository's convention.
        {ExSlop.Check.Readability.NarratorDoc, false}
      ]
    }
  ]
}
