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
    iex --sname "{{ sname }}" --erl "{{ erl }}" -S mix serve

up:
    docker compose up -d
    just serve

format:
    mix format
    mix assets.format

check:
    mix usage_rules.sync --check
    mix format.check
    mix assets.format.check
    mix assets.lint
    mix assets.test
    mix typecheck
    mix test
