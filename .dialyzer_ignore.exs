# Dialyzer warning filters.
#
# Entries must stay narrow: one exact file, warning type, and line. Do not add
# blanket regexes or whole-file entries; the backend quality gate must keep
# unrelated findings enabled.

# `Multi.new() |> Multi.insert/3` in `transact_user_with_identity/3` hits a
# known opacity-analysis false positive: the opaque `Ecto.Multi.t()` returned
# by `new/0` is structurally expanded before `insert/3`'s opaque first
# parameter is checked. The pipeline usage is correct Ecto API usage.
[{"lib/d20/accounts.ex", :call_without_opaque}]
