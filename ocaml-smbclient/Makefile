# OCaml-Smbclient.
#
# Copyright 2003 by the Savonet team.
#
# $Id$

PROGNAME = ocaml-smbclient
DISTFILES = bootstrap CHANGES configure configure.ac COPYING Makefile README \
            src/*Makefile* src/META.in src/*.ml src/*.mli src/*.c \
            examples/configure* examples/*Makefile* examples/*.ml \
            doc/html install-sh config.sub config.guess

all:

all byte opt install uninstall update:
	$(MAKE) -C src $@

doc:
	$(MAKE) -C src htdoc
	mkdir -p doc
	cp -r src/doc/smbclient/html doc
	rm -rf src/doc

clean:
	-$(MAKE) -C src clean
	-$(MAKE) -C examples clean

distclean: clean
	rm -rf autom4te.cache config.log config.status src/META src/Makefile
	rm -rf docs/html
	$(MAKE) -C examples distclean

dist: doc
	VERSION="$(shell grep 'AC_INIT' configure.ac)"; \
		VERSION=`echo "$$VERSION" | sed -e 's/AC_INIT([^,]*, \([^,]*\), .*)/\1/'`; \
		mkdir $(PROGNAME)-$$VERSION; \
		cp -R -L --parents $(DISTFILES) $(PROGNAME)-$$VERSION; \
		tar zcvf $(PROGNAME)-$$VERSION.tar.gz $(PROGNAME)-$$VERSION; \
		rm -rf $(PROGNAME)-$$VERSION

.PHONY: all byte opt install uninstall update doc clean distclean dist
