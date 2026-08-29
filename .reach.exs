# Reach architecture policy for D20.
#
# Pure D20 domain and game-policy modules must not depend on the web layer
# (D20Web.*). The application composition root and the session runtime server
# intentionally publish through web-owned processes (Endpoint, Presence,
# session and workspace channels), so they are classified as runtime adapters
# before the broad domain pattern; first matching layer wins.
#
# `mix reach.check --arch` makes the domain-to-web rule blocking. Heuristic
# `--smells` output is advisory review evidence and does not fail the gate.

[
  layers: [web: "D20Web.*", runtime: ["D20.Application", "D20.Sessions.Server"], domain: "D20.*"],
  deps: [forbidden: [{:domain, :web}]]
]
