.PHONY: setup start serve test build format format.check precommit

setup:
	pnpm install --recursive
	npx nx run-many -t setup --all

start:
	npx nx run-many -t start --all --tui

serve:
	$(MAKE) setup
	$(MAKE) start

test:
	npx nx run-many -t test --all --outputStyle=stream

build:
	npx nx run-many -t build --all --outputStyle=stream

format:
	npx nx run-many -t format --all --outputStyle=stream

format.check:
	npx nx run-many -t format.check --all --outputStyle=stream

precommit:
	npx nx run-many -t precommit --all --outputStyle=stream
