# ExDNA configuration for D20.
#
# Scope: the `mix ci` alias analyzes `lib` explicitly. The measured baseline of
# 14 exact clones is locked as the `--max-clones` budget in that alias: any
# additional duplication fails the gate, and the budget must be reduced (never
# raised) when accepted cleanup removes clones.
#
# Reviewed clone groups (tracked in issue #179):
# - lib/d20_web/auth — provider flows (google, discord, facebook, apple,
#   steam) deliberately mirror the same intent/registration/verification
#   shape; each provider module stays self-contained by convention.
# - lib/d20/koala_rescue_club, lib/d20/next_station_london, lib/d20/qwinto —
#   game validation pipelines share require_* scaffolding because game
#   namespaces own their rules independently.

%{min_mass: 30, min_occurrences: 2, literal_mode: :keep, normalize_pipes: false}
