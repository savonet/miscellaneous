/*
   Copyright 2003-2004 Savonet team

   This file is part of Ocaml-smbclient.

   Ocaml-smbclient is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   Ocaml-smbclient is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with Ocaml-smbclient; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

   Some parts Copyright 1996 Institut National de Recherche en
   Informatique et en Automatique.
   These parts are licensed under the GNU Library General Public
   License version 2, with this special exception:
   "You may link, statically or dynamically, a "work that uses the
   Library" with a publicly distributed version of the Library to
   produce an executable file containing portions of the Library, and
   distribute that executable file under terms of your choice, without
   any of the additional requirements listed in clause 6 of the GNU
   Library General Public License.  By "a publicly distributed version
   of the Library", we mean either the unmodified Library as
   distributed by INRIA, or a modified version of the Library that is
   distributed under the conditions defined in clause 3 of the GNU
   Library General Public License.  This exception does not however
   invalidate any other reasons why the executable file might be
   covered by the GNU Library General Public License."
*/

/**
   Bindings to the libsmbclient.

   @author Gaétan Richard, Samuel Mimram, Julien Cristau
**/

/* $Id$ */

#include <caml/fail.h>      /* exception       */
#include <caml/memory.h>    /* register_*_root */
#include <caml/mlvalues.h>  /* *_val           */
#include <caml/callback.h>  /* callback        */
#include <caml/alloc.h>     /* copy_*          */
#include <caml/misc.h>      /* CAMLprim        */

#include <stdio.h>
#include <string.h>

#include <errno.h>

#include <libsmbclient.h>

#define Nothing ((value) 0)

#define UNIX_BUFFER_SIZE 16384

/* TODO: not portable */
#define Val_file_offset(fofs) caml_copy_int64(fofs)
#define File_offset_val(v) ((off_t) Int64_val(v))

/* from ocaml/otherlibs/unix/cst2constr.c */
value smb_cst_to_constr(int n, int *tbl, int size, int deflt)
{
  int i;
  for (i = 0; i < size; i++)
    if (n == tbl[i]) return Val_int(i);
  return Val_int(deflt);
}

int smb_error_table[] = {
  ENOMEM, EBUSY, EBADF, ENOENT, EINVAL, EEXIST, EISDIR, EACCES, ENODEV,
  ENOTDIR, EPERM, EXDEV, ENOTEMPTY, ENOTSUP, ENETUNREACH
};

static value * samba_error_exn = NULL;

/* adapted from ocaml/otherlibs/unix/unixsupport.c */
void samba_error(int errcode, char *cmdname, value cmdarg)
{
  value res;
  value name = Val_unit, err = Val_unit, arg = Val_unit;
  int errconstr;

  Begin_roots3 (name, err, arg);
    arg = cmdarg == Nothing ? copy_string("") : cmdarg;
    name = copy_string(cmdname);
    errconstr =
      smb_cst_to_constr(errcode, smb_error_table, sizeof(smb_error_table)/sizeof(int), -1);
    if (errconstr == Val_int(-1)) {
      err = alloc_small(1, 0);
      Field(err, 0) = Val_int(errcode);
    } else {
      err = errconstr;
    }
    if (samba_error_exn == NULL) {
      samba_error_exn = caml_named_value("Smbclient.Samba_error");
      if (samba_error_exn == NULL)
        invalid_argument("Exception Smbclient.Samba_error not initialized, please link smbclient.cma");
    }
    res = alloc_small(4, 0);
    Field(res, 0) = *samba_error_exn;
    Field(res, 1) = err;
    Field(res, 2) = name;
    Field(res, 3) = arg;
  End_roots();
  mlraise(res);
}

void serror(char *cmdname, value cmdarg)
{
  samba_error(errno, cmdname, cmdarg);
}

/* from ocaml/otherlibs/unix/errmsg.c */
CAMLprim value samba_error_message(value err)
{
  int errnum;
  errnum = Is_block(err) ? Int_val(Field(err, 0)) : smb_error_table[Int_val(err)];
  return copy_string(strerror(errnum));
}

/*
 *  Authentification function
 */

/** The authentication fonction in Caml language */
static value auth_fn_caml ;

/** The authentication function in C language */
static void auth_fn(const char *srv,
		    const char *shr,
		    char *wg, int wglen,
		    char *un, int unlen,
		    char *pw, int pwlen)
{
  CAMLlocal1(res);
  value args[] = { copy_string(srv), copy_string(shr), copy_string(wg), copy_string(un) };

  /* re-acquire the master lock before the callback */
  leave_blocking_section();
  /* apply the Caml function to find the needed arguments */
  res = callbackN(auth_fn_caml, 4, args);
  enter_blocking_section();

#ifdef DEBUG
  printf("smbclient - workgroup: %s\n", String_val(Field(res,0)));
  printf("smbclient - username: %s\n", String_val(Field(res,1)));
  printf("smbclient - password: %s\n", String_val(Field(res,2)));
#endif

  if (string_length (Field(res,0)) >= wglen ||
      string_length (Field(res,1)) >= unlen ||
      string_length (Field(res,2)) >= pwlen)
    // TODO: find a better way to report the error ?
    caml_raise_out_of_memory();

  strcpy(wg, String_val(Field(res, 0))) ;
  strcpy(un, String_val(Field(res, 1))) ;
  strcpy(pw, String_val(Field(res, 2))) ;
}

/** Initialisation of samba */
CAMLprim value ocaml_samba_init (value fn, value debug)
{
  CAMLparam2(fn, debug);
  int ret;
  register_global_root(&auth_fn_caml);

  auth_fn_caml = fn;
  enter_blocking_section();
  ret = smbc_init (auth_fn, Int_val(debug));
  leave_blocking_section();
  if (ret) serror("smbc_init", Nothing);

  CAMLreturn (Val_unit);
}

/** Is the file available? */
CAMLprim value ocaml_samba_isavail(value furl)
{
  CAMLparam1(furl);
  char * name = String_val(furl);
  struct stat st;
  int ret;
  enter_blocking_section();
  ret = smbc_stat(name, &st);
  leave_blocking_section();
  if (ret < 0)
      CAMLreturn(Val_false);

  CAMLreturn(Val_true);
}

static int smb_open_flag_table[] = {
  O_RDONLY, O_WRONLY, O_RDWR, O_CREAT, O_EXCL, O_TRUNC, O_APPEND
};

/** Open a file */
CAMLprim value ocaml_samba_open(value furl, value flags, value mode)
{
  CAMLparam3(furl, flags, mode);
  int ret;

  enter_blocking_section();
  ret = smbc_open(String_val(furl), convert_flag_list(flags, smb_open_flag_table), Int_val(mode));
  leave_blocking_section();

  if (ret < 0)
    serror("smbc_open",furl);

  CAMLreturn (Val_int(ret));
}

static int seek_command_table[] = {
  SEEK_SET, SEEK_CUR, SEEK_END
};

/** Seek in a file */
CAMLprim value ocaml_samba_lseek(value fd, value offset, value whence)
{
  CAMLparam3(fd, offset, whence);
  off_t ret;

  enter_blocking_section();
  ret = smbc_lseek(Int_val(fd), Long_val(offset),
		   seek_command_table[Int_val(whence)]);
  leave_blocking_section();
  if (ret == (off_t)-1)
    serror("smbc_lseek", Nothing);
  if (ret > Max_long) samba_error(EOVERFLOW, "smbc_lseek", Nothing);

  CAMLreturn(Val_long(ret));
}

CAMLprim value ocaml_samba_lseek64(value fd, value ofs, value cmd)
{
  CAMLparam3(fd, ofs, cmd);
  off_t ret;

  enter_blocking_section();
  ret = smbc_lseek(Int_val(fd), File_offset_val(ofs),
                       seek_command_table[Int_val(cmd)]);
  leave_blocking_section();
  if (ret == (off_t)-1) serror("smbc_lseek", Nothing);
  CAMLreturn(Val_file_offset(ret));
}

/** Read a file. */
CAMLprim value ocaml_samba_read(value fd, value buf, value ofs, value len)
{
  long numbytes;
  int ret;
  char iobuf[UNIX_BUFFER_SIZE];

  Begin_root (buf);
    numbytes = Long_val(len);
    if (numbytes > UNIX_BUFFER_SIZE) numbytes = UNIX_BUFFER_SIZE;
    enter_blocking_section();
    ret = smbc_read(Int_val(fd), iobuf, (int) numbytes);
    leave_blocking_section();
    if (ret < 0) {
      if (!errno) { /* end_of_file */
	caml_raise_end_of_file();
      }
      else {
      serror("smbc_read", Nothing);
      }
    }
    memmove (&Byte(buf, Long_val(ofs)), iobuf, ret);
  End_roots();
  return Val_int(ret);
}

/** Close a file. */
CAMLprim value ocaml_samba_close(value fd)
{
  CAMLparam1(fd);
  int ret;

  enter_blocking_section();
  ret = smbc_close(Int_val(fd));
  leave_blocking_section();
  if (ret) serror("smbc_close", Nothing);

  CAMLreturn (Val_unit);
}



/** Open a directory. */
CAMLprim value ocaml_samba_opendir(value durl)
{
  CAMLparam1(durl);

  int dir;

  enter_blocking_section();
  dir = smbc_opendir(String_val(durl));
  leave_blocking_section();
  if (dir < 0)
    serror("smbc_opendir", durl);

  CAMLreturn(Val_int(dir));
}


/** Close a directory. */
CAMLprim value ocaml_samba_closedir(value dh)
{
  CAMLparam1(dh);
  int ret;

  enter_blocking_section();
  ret = smbc_closedir(Int_val(dh));
  leave_blocking_section();
  if (ret) serror("smbc_closedir", Nothing);

  CAMLreturn(Val_unit);
}


/** Read a directory. */
CAMLprim value ocaml_samba_readdir(value dh)
{
  CAMLparam1(dh);

  struct smbc_dirent* res;

  CAMLlocal1(result);

  enter_blocking_section();
  res = smbc_readdir(Int_val(dh));
  leave_blocking_section();

  if (!res) {
    /* TODO: is this the right way to check for EOF? */
    if (!errno) raise_end_of_file();
    serror("smbc_readdir", Nothing);
  }

  result = alloc_tuple(3);
  Store_field(result, 0, Val_int(res->smbc_type - 1));
  Store_field(result, 1, copy_string(res->comment));
  Store_field(result, 2, copy_string(res->name));
  CAMLreturn(result);
}
