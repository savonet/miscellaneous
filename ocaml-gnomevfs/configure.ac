AC_INIT(ocaml-gnomevfs,0.1)

AC_PROG_CC

AC_CANONICAL_SYSTEM

PKG_PROG_PKG_CONFIG

PKG_CHECK_MODULES(gnome_vfs, gnome-vfs-2.0)

LIBS="$LIBS -lgnomevfs-2"
CFLAGS="$CFLAGS `pkg-config --cflags gnome-vfs-2.0`"

GNOME_VFS_INCLUDES=/usr/include/gnome-vfs-2.0
GNOME_VFS_ERRORS=`grep "^[[[:space:]]]GNOME_VFS_ERROR_" $GNOME_VFS_INCLUDES/libgnomevfs/gnome-vfs-result.h|sed -e 's/^\(\s*\)GNOME_VFS_ERROR_\(.*\),$/\1| \2/g'`

GNOME_VFS_ERRORS=`echo $GNOME_VFS_ERRORS`
#GNOME_VFS_ERRORS=`eval $GNOME_VFS_ERRORS`

AC_SUBST(GNOME_VFS_ERRORS)

AC_CONFIG_FILES(src/Makefile)
AC_CONFIG_FILES(src/gnomevfs.ml)
AC_CONFIG_FILES(src/gnomevfs.mli)

AC_OUTPUT
