# OCaml-Shout examples.
#
# Copyright 2003-2006 by the Savonet team
#
# $Id$

all: shoutfile

clean: clean-shoutfile

distclean:
	rm -rf autom4te.cache config.log config.status
	rm -f Makefile.shoutfile

shoutfile:
	$(MAKE) -f Makefile.shoutfile

clean-shoutfile:
	$(MAKE) -f Makefile.shoutfile clean

.PHONY: clean-shoutfile distclean clean all
