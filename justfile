default:
    @just --list

[no-exit-message]
[positional-arguments]
mix +args:
    @mix "$@"

[no-exit-message]
[positional-arguments]
[working-directory('assets')]
assets +args:
    @bun run "$@"

[arg("erl", long="erl")]
[arg("sname", long="sname")]
[no-exit-message]
serve sname="d20" erl="-proto_dist inet6_tcp":
    mix setup
    watchexec --restart --shell=none --wrap-process=none --ignore-nothing \
        --watch envs --watch config -- \
        direnv exec . iex --sname "{{ sname }}" --erl "{{ erl }}" -S mix serve

[private]
restart-or-serve:
    if epmd -names | grep -q '[[:space:]]d20[[:space:]]'; then touch "config/${MIX_ENV:-dev}.exs"; else just serve; fi

up:
    docker compose up -d
    just restart-or-serve

format:
    mix format
    mix assets.format

check:
    mix format.check
    mix assets.format.check
    mix assets.lint
    mix assets.test
    mix typecheck
    mix test
