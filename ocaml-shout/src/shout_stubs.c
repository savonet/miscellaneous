/*
  Copyright 2003-2006 Savonet team

  This file is part of Ocaml-shout.

  Ocaml-shout is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  Ocaml-shout is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Ocaml-shout; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

/**
 * Libshout 2 bindings for OCaml.
 *
 * @author Samuel Mimram
 */

/* $Id$ */

#define CAML_NAME_SPACE
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/misc.h>
#include <caml/mlvalues.h>
#include <caml/signals.h>

#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <shout/shout.h>

#define Shout_val(v) (*((shout_t**)Data_custom_val(v)))

static void finalize_shout(value block)
{
  shout_t *x = Shout_val(block);
  if (shout_get_connected(x) == SHOUTERR_CONNECTED)
      shout_close(x) ;
  shout_free(x) ;
}

static struct custom_operations shout_ops =
{
  "ocaml_shout_shout",
  finalize_shout,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

CAMLprim value ocaml_shout_init(value unit)
{
  shout_init();
  return Val_unit;
}

CAMLprim value ocaml_shout_shutdown(value unit)
{
  shout_shutdown();
  return Val_unit;
}

CAMLprim value ocaml_shout_version(value unit)
{
  CAMLparam0();
  CAMLlocal1(block);
  int major, minor, patch;
  const char *version = shout_version(&major, &minor, &patch);
  block = caml_alloc_tuple(4);
  Store_field(block, 0, caml_copy_string(version));
  Store_field(block, 1, Val_int(major));
  Store_field(block, 2, Val_int(minor));
  Store_field(block, 3, Val_int(patch));
  CAMLreturn(block);
}

CAMLprim value ocaml_shout_new(value unit)
{
  CAMLparam0();
  CAMLlocal1(block);
  shout_t *s = shout_new();
  if (s == NULL)
    caml_raise_constant(*caml_named_value("shout_exn_malloc"));
  block = caml_alloc_custom(&shout_ops, sizeof(shout_t*), 0, 1);
  Shout_val(block) = s;
  CAMLreturn(block);
}

CAMLprim value ocaml_shout_get_error(value block)
{
  const char *error = shout_get_error(Shout_val(block));
  return caml_copy_string(error);
}

CAMLprim value ocaml_shout_get_errno(value block)
{
  int error = shout_get_errno(Shout_val(block));
  return Val_int(error);
}

CAMLprim value ocaml_shout_get_connected(value block)
{
  return (shout_get_connected(Shout_val(block)) == SHOUTERR_CONNECTED ? Val_true : Val_false);
}

static void check_errors(int err)
{
  switch (err)
    {
    case SHOUTERR_SUCCESS:
      return;

    case SHOUTERR_INSANE:
      caml_raise_constant(*caml_named_value("shout_exn_insane"));
      break;

    case SHOUTERR_NOCONNECT:
      caml_raise_constant(*caml_named_value("shout_exn_no_connect"));
      break;

    case SHOUTERR_NOLOGIN:
      caml_raise_constant(*caml_named_value("shout_exn_no_login"));
      break;

    case SHOUTERR_SOCKET:
      caml_raise_constant(*caml_named_value("shout_exn_socket"));
      break;

    case SHOUTERR_MALLOC:
      caml_raise_constant(*caml_named_value("shout_exn_malloc"));
      break;

    case SHOUTERR_METADATA:
      caml_raise_constant(*caml_named_value("shout_exn_metadata"));
      break;

    case SHOUTERR_CONNECTED:
      caml_raise_constant(*caml_named_value("shout_exn_connected"));
      break;

    case SHOUTERR_UNCONNECTED:
      caml_raise_constant(*caml_named_value("shout_exn_unconnected"));
      break;

    case SHOUTERR_UNSUPPORTED:
      caml_raise_constant(*caml_named_value("shout_exn_unsupported"));
      break;

    default:
      assert(42 == 666);
      break;
    }
}

static value unit_or_error(int err)
{
  check_errors(err);
  return Val_unit;
}

CAMLprim value ocaml_shout_set_host(value block, value host)
{
  CAMLparam2(block, host);
  shout_t *s = Shout_val(block);
  int ret = shout_set_host(s, String_val(host));
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_get_host(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  const char *host = shout_get_host(s);
  CAMLreturn(caml_copy_string(host));
}

CAMLprim value ocaml_shout_set_port(value block, value port)
{
  CAMLparam2(block, port);
  shout_t *s = Shout_val(block);
  int ret = shout_set_port(s, (unsigned short)Int_val(port));
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_get_port(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  int port = shout_get_port(s);
  CAMLreturn(Val_int(port));
}

CAMLprim value ocaml_shout_set_password(value block, value password)
{
  CAMLparam2(block, password);
  shout_t *s = Shout_val(block);
  int ret = shout_set_password(s, String_val(password));
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_get_password(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  const char *password = shout_get_password(s);
  CAMLreturn(caml_copy_string(password));
}

CAMLprim value ocaml_shout_set_mount(value block, value mount)
{
  CAMLparam2(block, mount);
  shout_t *s = Shout_val(block);
  int ret = shout_set_mount(s, String_val(mount));
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_get_mount(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  const char *mount = shout_get_mount(s);
  CAMLreturn(caml_copy_string(mount));
}

CAMLprim value ocaml_shout_set_name(value block, value name)
{
  CAMLparam2(block, name);
  shout_t *s = Shout_val(block);
  int ret = shout_set_name(s, String_val(name));
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_get_name(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  const char *name = shout_get_name(s);
  CAMLreturn(caml_copy_string(name));
}

CAMLprim value ocaml_shout_set_url(value block, value url)
{
  CAMLparam2(block, url);
  shout_t *s = Shout_val(block);
  int ret = shout_set_url(s, String_val(url));
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_get_url(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  const char *url = shout_get_url(s);
  CAMLreturn(caml_copy_string(url));
}

CAMLprim value ocaml_shout_set_genre(value block, value genre)
{
  CAMLparam2(block, genre);
  shout_t *s = Shout_val(block);
  int ret = shout_set_genre(s, String_val(genre));
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_get_genre(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  const char *genre = shout_get_genre(s);
  CAMLreturn(caml_copy_string(genre));
}

CAMLprim value ocaml_shout_set_user(value block, value username)
{
  CAMLparam2(block, username);
  shout_t *s = Shout_val(block);
  int ret = shout_set_user(s, String_val(username));
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_get_user(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  const char *username = shout_get_user(s);
  CAMLreturn(caml_copy_string(username));
}

CAMLprim value ocaml_shout_set_agent(value block, value username)
{
  CAMLparam2(block, username);
  shout_t *s = Shout_val(block);
  int ret = shout_set_agent(s, String_val(username));
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_get_agent(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  const char *username = shout_get_agent(s);
  CAMLreturn(caml_copy_string(username));
}

CAMLprim value ocaml_shout_set_description(value block, value desription)
{
  CAMLparam2(block, desription);
  shout_t *s = Shout_val(block);
  int ret = shout_set_description(s, String_val(desription));
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_get_description(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  const char *desription = shout_get_description(s);
  CAMLreturn(caml_copy_string(desription));
}

CAMLprim value ocaml_shout_set_dumpfile(value block, value dumpfile)
{
  CAMLparam2(block, dumpfile);
  shout_t *s = Shout_val(block);
  int ret = shout_set_dumpfile(s, String_val(dumpfile));
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_get_dumpfile(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  const char *dumpfile = shout_get_dumpfile(s);
  CAMLreturn(caml_copy_string(dumpfile));
}

CAMLprim value ocaml_shout_set_audio_info(value block, value name, value val)
{
  CAMLparam3(block, name, val);
  shout_t *s = Shout_val(block);
  int ret = shout_set_audio_info(s, String_val(name), String_val(val));
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_get_audio_info(value block, value name)
{
  CAMLparam2(block, name);
  shout_t *s = Shout_val(block);
  const char *val = shout_get_audio_info(s, String_val(name));
  CAMLreturn(caml_copy_string(val));
}

CAMLprim value ocaml_shout_set_public(value block, value public)
{
  CAMLparam2(block, public);
  shout_t *s = Shout_val(block);
  int ret = shout_set_public(s, (unsigned int)Int_val(public));
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_get_public(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  unsigned int public = shout_get_public(s);
  CAMLreturn(public?Val_true:Val_false);
}

static int data_format_table[] = {SHOUT_FORMAT_VORBIS, SHOUT_FORMAT_MP3};

CAMLprim value ocaml_shout_set_format(value block, value data_format)
{
  CAMLparam2(block, data_format);
  shout_t *s = Shout_val(block);
  int ret = shout_set_format(s, data_format_table[Int_val(data_format)]);
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_get_format(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  int data_format = shout_get_format(s);
  /* Not very clean: we should use data_format_table */
  CAMLreturn(Val_int(data_format));
}

static int protocol_table[] = {SHOUT_PROTOCOL_HTTP, SHOUT_PROTOCOL_XAUDIOCAST, SHOUT_PROTOCOL_ICY};

CAMLprim value ocaml_shout_set_protocol(value block, value protocol)
{
  CAMLparam2(block, protocol);
  shout_t *s = Shout_val(block);
  int ret = shout_set_protocol(s, protocol_table[Int_val(protocol)]);
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_get_protocol(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  int protocol = shout_get_protocol(s);
  /* Not very clean: we should use protocol_table */
  CAMLreturn(Val_int(protocol));
}

CAMLprim value ocaml_shout_open(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  int ret = shout_open(s);
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_close(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  int ret = shout_close(s);
  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_send(value block, value data)
{
  CAMLparam2(block, data);
  shout_t *s = Shout_val(block);
  size_t len = caml_string_length(data);
  unsigned char* dat = malloc(len);
  int ret;

  memcpy(dat, String_val(data), len);
  caml_enter_blocking_section();
  ret = shout_send(s, dat, len);
  caml_leave_blocking_section();
  free(dat);

  CAMLreturn(unit_or_error(ret));
}

CAMLprim value ocaml_shout_send_raw(value block, value data)
{
  CAMLparam2(block, data);
  shout_t *s = Shout_val(block);
  size_t len = caml_string_length(data);
  unsigned char* dat = malloc(len);
  int ret;

  memcpy(dat, String_val(data), len);
  caml_enter_blocking_section();
  ret = shout_send_raw(s, dat, len);
  caml_leave_blocking_section();
  free(dat);

  CAMLreturn(Val_int(ret));
}

CAMLprim value ocaml_shout_sync(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  caml_enter_blocking_section();
  shout_sync(s);
  caml_leave_blocking_section();
  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_shout_delay(value block)
{
  CAMLparam1(block);
  shout_t *s = Shout_val(block);
  int delay = shout_delay(s);
  CAMLreturn(Val_int(delay));
}

CAMLprim value ocaml_shout_set_metadata(value block, value data)
{
  CAMLparam2(block, data);
  CAMLlocal1(c);
  shout_t *s = Shout_val(block);
  shout_metadata_t *metadata = shout_metadata_new();
  int i, ret;
  char *name, *val;

  for (i=0; i<Wosize_val(data); i++)
    {
      c = Field(data, i);
      name = String_val(Field(c, 0));
      val = String_val(Field(c, 1));
      shout_metadata_add(metadata, name, val);
    }
  ret = shout_set_metadata(s, metadata);
  shout_metadata_free(metadata);
  CAMLreturn(unit_or_error(ret));
}
