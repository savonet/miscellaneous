#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/signals.h>

#include <string.h>
#include <assert.h>
#include <stdio.h>

#include <faac.h>

CAMLprim value ocaml_faac_get_version(value unit)
{
  char *id, *copyright;
  value ans;

  faacEncGetVersion(&id, &copyright);
  ans = caml_alloc_tuple(2);
  Store_field(ans, 0, caml_copy_string(id));
  Store_field(ans, 1, caml_copy_string(copyright));
  return ans;
}

CAMLprim value ocaml_faac_open(value rate, value chans)
{
  unsigned long samples, maxbytes;
  faacEncHandle eh;
  faacEncConfigurationPtr conf;
  value ans;

  eh = faacEncOpen(Int_val(rate), Int_val(chans), &samples, &maxbytes);

  /* TODO: raise */
  assert(eh);

  /* TODO: allow other data than floating-point? */
  conf = faacEncGetCurrentConfiguration(eh);
  conf->inputFormat = FAAC_INPUT_FLOAT;
  faacEncSetConfiguration(eh, conf);

  ans = caml_alloc_tuple(3);
  Store_field(ans, 0, (value)eh);
  Store_field(ans, 1, Val_int(samples));
  Store_field(ans, 2, Val_int(maxbytes));
  return ans;
}

CAMLprim value ocaml_faac_close(value eh)
{
  faacEncClose((faacEncHandle)eh);
  return Val_unit;
}

#define set_param(d,v) \
  if (Is_block(v)) \
    d = Int_val(Field(v, 0))

CAMLprim value ocaml_faac_set_configuration(value eh, value mpeg_version, value quantqual, value bitrate, value bandwidth)
{
  faacEncConfigurationPtr conf = faacEncGetCurrentConfiguration((faacEncHandle)eh);
  set_param(conf->mpegVersion, mpeg_version);
  set_param(conf->quantqual, quantqual);
  set_param(conf->bitRate, bitrate);
  set_param(conf->bandWidth, bandwidth);
  faacEncSetConfiguration((faacEncHandle)eh, conf);
  return Val_unit;
}

CAMLprim value ocaml_faac_encode(value _eh, value _inbuf, value _inbufofs, value _inbuflen, value _outbuf, value _outbufofs)
{
  CAMLparam2(_inbuf, _outbuf);
  faacEncHandle eh = (faacEncHandle)_eh;
  float *inbuf;
  unsigned char *outbuf;
  int inbufofs = Int_val(_inbufofs);
  int inbuflen = Int_val(_inbuflen);
  int outbufofs = Int_val(_outbufofs);
  int outbuflen = caml_string_length(_outbuf) - outbufofs;
  int i, ret;

  inbuf = malloc(inbuflen * sizeof(float));
  outbuf = malloc(outbuflen);
  for (i = 0; i < inbuflen; i++)
    inbuf[i] = Double_field(_inbuf, i+inbufofs) * 32768;

  caml_enter_blocking_section();
  ret = faacEncEncode(eh, (int32_t*)inbuf, inbuflen, outbuf, outbuflen);
  caml_leave_blocking_section();

  /* TODO: raise */
  assert(ret >= 0);

  memcpy(String_val(_outbuf) + outbufofs, outbuf, ret);
  CAMLreturn(Val_int(ret));
}

CAMLprim value ocaml_faac_encode_byte(value *argv, int argc)
{
  return ocaml_faac_encode(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}
