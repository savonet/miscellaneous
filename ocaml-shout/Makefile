# Copyright 2003-2006 by the Savonet team
#
# $Id$

PROGNAME = ocaml-shout
DISTFILES = bootstrap CHANGES configure configure.ac COPYING \
            Makefile README aclocal.m4 \
            src/OCamlMakefile src/Makefile.in \
            src/META.in src/*.ml src/*.mli src/*.c src/*.h \
            examples/configure* examples/*Makefile* examples/*.ml \
            doc/html

all:
	$(MAKE) -C src

opt:
	$(MAKE) -C src opt

doc:
	$(MAKE) -C src htdoc
	mkdir -p doc
	rm -rf doc/html
	mv src/doc/shout/html doc
	rm -rf src/doc

clean:
	-$(MAKE) -C src clean
	-$(MAKE) -C examples clean

distclean: clean
	rm -rf autom4te.cache config.log config.status src/META src/Makefile
	rm -rf doc
	$(MAKE) -C examples distclean

install:
	$(MAKE) -C src libinstall

uninstall:
	$(MAKE) -C src libuninstall

dist: doc
	VERSION="$(shell grep 'AC_INIT' configure.ac)"; \
		VERSION=`echo "$$VERSION" | sed -e 's/AC_INIT([^,]*, \([^,]*\), .*)/\1/'`; \
		mkdir $(PROGNAME)-$$VERSION; \
		cp -r --parents $(DISTFILES) $(PROGNAME)-$$VERSION; \
		tar zcvf $(PROGNAME)-$$VERSION.tar.gz $(PROGNAME)-$$VERSION; \
		rm -rf $(PROGNAME)-$$VERSION

.PHONY: all opt doc clean distclean install uninstall dist
