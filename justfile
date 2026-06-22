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

[script]
up:
    set -eu

    if ! k3d cluster list d20 >/dev/null 2>&1; then
      k3d cluster create --config k3d.yaml
    fi

    kubectl config use-context k3d-d20
    tilt up --stream

[script]
down:
    set -eu

    if ! k3d cluster list d20 >/dev/null 2>&1; then
      exit 0
    fi

    kubectl config use-context k3d-d20
    tilt down || true
    k3d cluster delete d20

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
