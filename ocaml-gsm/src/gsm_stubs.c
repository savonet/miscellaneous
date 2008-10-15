/*
  Copyright 2003-2008 Savonet team

  This file is part of Ocaml-gsm.

  Ocaml-gsm is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  Ocaml-gsm is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Ocaml-gsm; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include <caml/custom.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/fail.h>
#include <caml/alloc.h>
#include <caml/signals.h>

#include <gsm.h>

#include <string.h>

#define Gsm_val(v) (*((gsm*)Data_custom_val(v)))

static void finalize_gsm(value v)
{
  gsm g = Gsm_val(v);
  gsm_destroy(g);
}

static struct custom_operations gsm_ops =
{
  "ocaml_gsm",
  finalize_gsm,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

CAMLprim value ocaml_gsm_init(value unit)
{
  CAMLparam0();
  CAMLlocal1(ret);
  gsm g = gsm_create();
  if (g == NULL) caml_failwith("gsm_init");
  ret = caml_alloc_custom(&gsm_ops, sizeof(gsm), 1, 0);
  Gsm_val(ret) = g;
  CAMLreturn(ret);
}

CAMLprim value ocaml_gsm_get(value e, value o)
{
  CAMLparam1(e);
  gsm g = Gsm_val(e);
  int option = Int_val(o);
  int *ret = NULL;

  gsm_option(g,option,ret);

  CAMLreturn(Val_int(ret));
}

CAMLprim value ocaml_gsm_set(value e, value o, value v)
{
  CAMLparam1(e);
  gsm g = Gsm_val(e);
  int x = Int_val(v);

  gsm_option(g,Int_val(o),&x);

  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_gsm_encode(value s, value d)
{
  CAMLparam2(s,d);
  CAMLlocal1(ret);
  gsm g = Gsm_val(s);
  gsm_signal signal[160];
  gsm_byte   bytes[33];
  int i;
  int n = sizeof(bytes);

  memset(bytes,0,n);
  for (i=0;i<159;i++)
    signal[i] = Int_val(Field(d,i));

  caml_enter_blocking_section();
  gsm_encode(g,signal,bytes);
  caml_leave_blocking_section(); 

  ret = caml_alloc_string(n);
  memcpy(String_val(ret),bytes,n);

  CAMLreturn(ret);
}

CAMLprim value ocaml_gsm_decode(value s, value d)
{
  CAMLparam2(s,d);
  CAMLlocal1(ret);
  gsm g = Gsm_val(s);
  gsm_signal signal[160];
  gsm_byte   bytes[33];
  int i;
 
  memset(signal,0,sizeof(signal)); 
  memcpy(bytes,String_val(d),33);

  caml_enter_blocking_section();
  gsm_decode(g,bytes,signal);
  caml_leave_blocking_section();

  ret = caml_alloc_tuple(160);
  for (i=0;i<159;i++)
    Store_field(ret,i,Val_int(signal[i]));

  CAMLreturn(ret);
}


