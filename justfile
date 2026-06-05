default:
    @just --list

setup:
    mix setup

[arg("sname", long)]
[arg("erl", long)]
[no-exit-message]
start sname="d20" erl="-proto_dist inet6_tcp":
    iex --sname "{{sname}}" --erl "{{erl}}" -S mix serve

[arg("sname", long)]
[arg("erl", long)]
[no-exit-message]
serve sname="d20" erl="-proto_dist inet6_tcp":
    just setup
    just start --sname "{{sname}}" --erl "{{erl}}"

up:
    docker compose up -d traefik
    just serve

down:
    docker compose down

test:
    mix test

build:
    mix deploy

typecheck:
    mix typecheck

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

db-create:
    mix ecto.create

db-migrate:
    mix ecto.migrate

db-reset:
    mix ecto.reset
