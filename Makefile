all: build

build:
	mdbook build

test: build
	cargo run

serve:
	mdbook serve

serve_open:
	mdbook serve --open
