
# check for one particular file of the sources 
AC_INIT(ocaml-faac, 0.1.2, savonet-users@lists.sourceforge.net)

VERSION=$PACKAGE_VERSION
AC_MSG_RESULT([configuring $PACKAGE_STRING])

# Add prefix to compilation variables
# if passed
if test "x$prefix" != "xNONE"; then
	CFLAGS="$CFLAGS -I$prefix/include"
	LDFLAGS="$LDFLAGS -L$prefix/lib"
	CPPFLAGS="$CPPFLAGS -I$prefix/include"
fi

AC_CHECK_OCAML_COMPILERS()

AC_PROG_CC()
AC_CHECK_TOOL([AR],[ar],no)
AC_SUBST(AR)
# Check for libfaac
FAAC_LIBS="-lfaac -lm"
FAAC_CFLAGS=""
FAAC_CPPFLAGS=""
ac_save_CPPFLAGS="$CPPFLAGS"
ac_save_CFLAGS="$CFLAGS"
ac_save_LIBS="$LIBS"
CPPFLAGS="$CPPFLAGS $FAAC_CPPFLAGS"
CFLAGS="$CFLAGS $FAAC_CFLAGS"
LIBS="$FAAC_LIBS $LIBS"
AC_CHECK_HEADERS([faac.h], [
                  AC_CHECK_FUNC([faacEncGetVersion], [ac_have_faac="yes"])
])
CPPFLAGS="$ac_save_CPPFLAGS"
CFLAGS="$ac_save_CFLAGS"
LIBS="$ac_save_LIBS"
if test "$ac_have_faac" != "yes"; then
  AC_MSG_ERROR([Cannot find libfaac.])
fi
CPPFLAGS="$CPPFLAGS $FAAC_CPPFLAGS"
CFLAGS="$CFLAGS $FAAC_CFLAGS"
LIBS="$LIBS $FAAC_LIBS"


# substitutions to perform
AC_SUBST(VERSION)

# Finally create the Makefile and samples
AC_CONFIG_FILES([Makefile],[chmod a-w Makefile])
AC_CONFIG_FILES([src/META])
AC_CONFIG_FILES([src/Makefile])
AC_OUTPUT
