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
    if epmd -names | awk -v requested_name="{{ sname }}" '$1 == "name" && $2 == requested_name { found = 1 } END { exit !found }'; then touch "config/${MIX_ENV:-dev}.exs"; else exec just start --sname "{{ sname }}" --erl "{{ erl }}"; fi

[arg("erl", long="erl")]
[arg("sname", long="sname")]
[no-exit-message]
[private]
start sname="d20" erl="-proto_dist inet6_tcp":
    mix setup
    exec watchexec --restart --shell=none --wrap-process=none --ignore-nothing \
        --watch envs --watch config -- \
        direnv exec . iex --sname "{{ sname }}" --erl "{{ erl }}" -S mix serve

[no-exit-message]
[positional-arguments]
[working-directory('assets')]
storybook *args:
    @bun run storybook "$@"

up:
    docker compose up -d
    just serve

format:
    mix format
    mix assets.format

check:
    mix format.check
    mix assets.format.check
    mix assets.lint
    mix assets.test
    mix typecheck
    mix assets.storybook
    mix test
