# OCaml-Fetch
#
# Copyright (c) 2003 by the Savonet team
#
# $Id$

PROGNAME = ocaml-fetch
DISTFILES = bootstrap CHANGES configure configure.ac COPYING Makefile README \
            src/*Makefile* src/META.in src/*.ml src/*.mli \
            examples/configure* examples/*Makefile* examples/*.ml examples/ufetch.1 \
            doc/html

all:
	$(MAKE) -C src

byte opt install uninstall update:
	$(MAKE) -C src $@

doc:
	$(MAKE) -C src htdoc
	mkdir -p doc
	rm -rf doc/html
	mv src/doc/fetch/html doc
	rm -rf src/doc

clean:
	-$(MAKE) -C src clean
	-$(MAKE) -C examples clean

distclean: clean
	rm -rf autom4te.cache config.log config.status 
	rm -f src/META src/Makefile
	rm -rf doc/html
	-$(MAKE) -C examples distclean

dist: doc
	VERSION="$(shell grep 'AC_INIT' configure.ac)"; \
		VERSION=`echo "$$VERSION" | sed -e 's/AC_INIT([^,]*, \([^,]*\), .*)/\1/'`; \
		mkdir $(PROGNAME)-$$VERSION; \
		cp -r --parents $(DISTFILES) $(PROGNAME)-$$VERSION; \
		tar zcvf $(PROGNAME)-$$VERSION.tar.gz $(PROGNAME)-$$VERSION; \
		rm -rf $(PROGNAME)-$$VERSION

.PHONY: doc distclean clean all byte opt install uninstall update dist
