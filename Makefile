.PHONY: setup start serve test build lint format format.check check

NX := pnpm exec nx

setup:
	pnpm install --recursive
	$(NX) run-many -t setup --all

start:
	$(NX) run-many -t start --all --tui

serve:
	$(MAKE) setup
	$(MAKE) start

test:
	$(NX) run-many -t test --all --outputStyle=stream-without-prefixes

build:
	$(NX) run-many -t build --all --outputStyle=stream-without-prefixes

lint:
	$(NX) run-many -t lint --all --outputStyle=stream-without-prefixes

format:
	$(NX) run-many -t format --all --outputStyle=stream-without-prefixes

format.check:
	$(NX) run-many -t format.check --all --outputStyle=stream-without-prefixes

check:
	$(NX) run-many -t format.check lint test --all --outputStyle=stream-without-prefixes
