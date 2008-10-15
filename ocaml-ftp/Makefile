# OCaml-Ftp.
#
# Copyright (c) 2003 by the Savonet team
#
# $Id$

PROGNAME = ocaml-ftp
DISTFILES = bootstrap CHANGES configure configure.ac COPYING Makefile README \
            src/*Makefile* src/META.in src/*.ml src/*.mli \
            doc/html

all byte opt update install uninstall:
	$(MAKE) -C src $@

doc:
	$(MAKE) -C src htdoc
	mkdir -p doc
	rm -rf doc/html
	mv src/doc/ftp/html doc
	rm -rf src/doc

clean:
	$(MAKE) -C src clean

distclean: clean
	rm -rf autom4te.cache config.log config.status src/META src/Makefile
	rm -rf doc/html

dist: doc
	VERSION="$(shell grep 'AC_INIT' configure.ac)"; \
		VERSION=`echo "$$VERSION" | sed -e 's/AC_INIT([^,]*, \([^,]*\), .*)/\1/'`; \
		mkdir $(PROGNAME)-$$VERSION; \
		cp -r --parents $(DISTFILES) $(PROGNAME)-$$VERSION; \
		tar zcvf $(PROGNAME)-$$VERSION.tar.gz $(PROGNAME)-$$VERSION; \
		rm -rf $(PROGNAME)-$$VERSION

.PHONY: doc dist
