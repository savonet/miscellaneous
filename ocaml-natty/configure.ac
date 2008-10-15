
# check for one particular file of the sources 
AC_INIT(ocaml-natty, 0.1.0, savonet-users@lists.sourceforge.net)

VERSION=$PACKAGE_VERSION
AC_MSG_RESULT([configuring $PACKAGE_STRING])

OCAMLFIND_LDCONF=""
AC_ARG_ENABLE([ldconf], AC_HELP_STRING([--disable-ldconf],[don't modify the dynamic loader configuration file (default is enable)]),[ac_enable_ldconf=$enableval],[ac_enable_ldconf=$enableval],[ac_enable_ldconf=yes])
if test "$ac_enable_ldconf" = no ; then
	AC_MSG_RESULT([disabling modification of ld.conf])
	OCAMLFIND_LDCONF=dummy
fi

# then we look for ocamlopt; if not present, we issue a warning
# if the version is not the same, we also discard it
# we set OCAMLBEST to "opt" or "byte", whether ocamlopt is available or not
AC_PATH_PROG(OCAMLOPT,ocamlopt,no)
OCAMLBEST=byte
if test "$OCAMLOPT" = no ; then
        AC_MSG_WARN(Cannot find ocamlopt; bytecode compilation only.)
else
            OCAMLBEST=opt
fi

AC_PATH_PROG(OCAMLFIND,ocamlfind,no)
if test "$OCAMLFIND" = no ; then
	AC_MSG_ERROR(Cannot find ocamlfind.)
fi

AC_MSG_CHECKING(for ocaml-bitstring)
if ($OCAMLFIND query bitstring > /dev/null 2>&1); then
      AC_MSG_RESULT(ok)
else
      AC_MSG_ERROR(not found.)
fi
requires="$requires bitstring bitstring.syntax"

if test "$OCAMLOPT" = no ; then
    BEST=byte
else
    BEST="byte opt"
fi

# substitutions to perform
AC_SUBST(VERSION)
AC_SUBST(OCAMLBEST)
AC_SUBST(OCAMLFIND)
AC_SUBST(OCAMLFIND_LDCONF)
AC_SUBST(BEST)
AC_SUBST(INC)
AC_SUBST(requires)

# Finally create the Makefile and samples
AC_CONFIG_FILES([Makefile],[chmod a-w Makefile])
AC_CONFIG_FILES([src/META])
AC_CONFIG_FILES([src/Makefile])
AC_OUTPUT
