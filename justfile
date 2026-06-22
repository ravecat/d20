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
[no-exit-message]
up:
    set -eu

    command -v garden >/dev/null
    docker buildx use default >/dev/null

    if ! k3d cluster list d20 >/dev/null 2>&1; then
      k3d cluster create --config k3d.yaml
    fi

    kubectl config use-context k3d-d20
    python3 scripts/discovery.py

    garden deploy backend --env local

    # Fresh k3d clusters do not have a Telepresence Traffic Manager.
    # In this Docker-mode setup, connect does not install it automatically.
    if ! kubectl get deployment traffic-manager -n ambassador >/dev/null 2>&1; then
      telepresence helm install
    fi

    telepresence connect --docker --namespace d20

    host_ip="$(docker network inspect bridge --format '{{{{(index .IPAM.Config 0).Gateway}}')"

    telepresence leave backend >/dev/null 2>&1 || true
    telepresence intercept backend --address "$host_ip" --port 5000:http --port 5174:vite --mount=false

    garden deploy --env local --sync='*' --logs

[script]
down:
    set -eu

    telepresence leave backend >/dev/null 2>&1 || true
    telepresence quit --stop-daemons || true

    if command -v garden >/dev/null && k3d cluster list d20 >/dev/null 2>&1; then
      kubectl config use-context k3d-d20
      garden delete env --env local || true
    fi

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
