SOURCES = liq.mli liq.ml bottle.mli bottle.ml main.ml
RESULT = bottle
LIBS = unix str dynlink irc
THREADS = yes
INCDIRS = ../../ocaml-irc/src

PLUGINS = bottle_default.ml

all: dc plugins

plugins:
	for p in $(PLUGINS); do ocamlc -c $$p; done

test: liq.cmo test.ml
	ocamlc unix.cma str.cma liq.cmo test.ml -o test
	./test

doc: htdoc

-include OCamlMakefile
