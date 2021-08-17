all: build

build:
	mdbook build

test: build
	cargo run
