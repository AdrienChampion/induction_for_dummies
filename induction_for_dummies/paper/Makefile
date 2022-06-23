all: build

target:
	mkdir -p target

build: target
	tectonic -o target src/main.tex

verbose: target
	tectonic --print -o target src/main.tex

clean:
	rm -rf target
