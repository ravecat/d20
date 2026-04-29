.PHONY: setup start serve test build lint format format.check check db.create db.migrate db.reset

setup:
	mix setup

start:
	iex --sname $${D20_NODE_NAME:-d20} --erl "-proto_dist inet6_tcp" -S mix serve

serve:
	$(MAKE) setup
	$(MAKE) start

test:
	mix test

build:
	mix deploy

lint:
	mix assets.lint

format:
	mix format
	mix assets.format

format.check:
	mix format.check
	mix assets.format.check

check:
	mix format.check
	mix assets.format.check
	mix assets.lint
	mix test

db.create:
	mix ecto.create

db.migrate:
	mix ecto.migrate

db.reset:
	mix ecto.reset
