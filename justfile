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
    @pkill -9 -f "[b]eam.smp.* -sname {{ sname }} " || true
    exec watchexec \
        --exit-on-error \
        --restart \
        --watch envs \
        --watch config \
        --watch mix.exs \
        --watch mix.lock \
        --no-vcs-ignore \
        --shell=none \
        --wrap-process=none \
        -- \
        direnv exec . iex \
            --sname "{{ sname }}" \
            --erl "{{ erl }}" \
            -S mix serve

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
    mix openspec.check
    mix assets.format.check
    mix assets.lint
    mix assets.test
    mix typecheck
    mix assets.storybook
    mix test
