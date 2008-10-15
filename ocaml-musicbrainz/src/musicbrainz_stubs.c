#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/signals.h>

#include <musicbrainz/mb_c.h>

#include <stdio.h>
#include <assert.h>

/* Maximum length of retreived data */
#define DATA_LEN 1024

static void cerr(int r)
{
  /* TODO: 1 is sometimes returned but is not really an error... */
  if (IsError(r) && r != 1)
    caml_raise_with_arg(*caml_named_value("musicbrainz_exn_error"), Val_int(r));
}

#define Mb_val(v) (*((musicbrainz_t*)Data_custom_val(v)))

static void finalize_mb(value mb)
{
  mb_Delete(Mb_val(mb));
}

static struct custom_operations state_ops =
{
  "ocaml_musicbrainz_t",
  finalize_mb,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

CAMLprim value ocaml_musicbrainz_new(value unit)
{
  CAMLparam1(unit);
  CAMLlocal1(ans);

  musicbrainz_t mb = mb_New();
  ans = caml_alloc_custom(&state_ops, sizeof(musicbrainz_t), 1, 0);
  Mb_val(ans) = mb;

  CAMLreturn(ans);
}

CAMLprim value ocaml_musicbrainz_get_version(value mb)
{
  CAMLparam1(mb);
  CAMLlocal1(ans);
  int mj, mn, rev;

  mb_GetVersion(Mb_val(mb), &mj, &mn, &rev);
  ans = caml_alloc_tuple(3);
  Store_field(ans, 0, mj);
  Store_field(ans, 1, mn);
  Store_field(ans, 2, rev);

  CAMLreturn(ans);
}

CAMLprim value ocaml_musicbrainz_set_server(value mb, value server, value port)
{
  cerr(mb_SetServer(Mb_val(mb), String_val(server), Int_val(port)));

  return Val_unit;
}

CAMLprim value ocaml_musicbrainz_set_debug(value mb, value d)
{
  mb_SetDebug(Mb_val(mb), Int_val(d));

  return Val_unit;
}

CAMLprim value ocaml_musicbrainz_set_proxy(value mb, value server, value port)
{
  cerr(mb_SetProxy(Mb_val(mb), String_val(server), Int_val(port)));

  return Val_unit;
}

CAMLprim value ocaml_musicbrainz_authenticate(value mb, value user, value pass)
{
  cerr(mb_Authenticate(Mb_val(mb), String_val(user), String_val(pass)));

  return Val_unit;
}

CAMLprim value ocaml_musicbrainz_set_device(value mb, value device)
{
  cerr(mb_SetDevice(Mb_val(mb), String_val(device)));

  return Val_unit;
}

CAMLprim value ocaml_musicbrainz_use_utf8(value mb, value u)
{
  mb_UseUTF8(Mb_val(mb), Int_val(u));

  return Val_unit;
}

CAMLprim value ocaml_musicbrainz_set_depth(value mb, value d)
{
  mb_SetDepth(Mb_val(mb), Int_val(d));

  return Val_unit;
}

CAMLprim value ocaml_musicbrainz_set_max_items(value mb, value m)
{
  mb_SetMaxItems(Mb_val(mb), Int_val(m));

  return Val_unit;
}

CAMLprim value ocaml_musicbrainz_query(value mb, value query)
{
  cerr(mb_Query(Mb_val(mb), String_val(query)));

  return Val_unit;
}

CAMLprim value ocaml_musicbrainz_query_with_args(value mb, value query, value vargs)
{
  int argslen = Wosize_val(vargs);
  char **args = malloc((argslen+1) * sizeof(char*));
  int i;

  for (i = 0; i < argslen; i++)
    args[i] = String_val(Field(vargs, i));
  args[argslen] = NULL;

  cerr(mb_QueryWithArgs(Mb_val(mb), String_val(query), args));

  free(args);

  return Val_unit;
}

CAMLprim value ocaml_musicbrainz_select(value mb, value query)
{
  cerr(mb_Select(Mb_val(mb), String_val(query)));

  return Val_unit;
}

CAMLprim value ocaml_musicbrainz_select1(value mb, value query, value ord)
{
  cerr(mb_Select1(Mb_val(mb), String_val(query), Int_val(ord)));

  return Val_unit;
}

CAMLprim value ocaml_musicbrainz_get_result_int(value mb, value result)
{
  return Val_int(mb_GetResultInt(Mb_val(mb), String_val(result)));
}

CAMLprim value ocaml_musicbrainz_get_result_data(value mb, value result)
{
  char data[DATA_LEN];

  cerr(mb_GetResultData(Mb_val(mb), String_val(result), data, DATA_LEN));

  /* TODO: is it always NULL-terminated? */
  return caml_copy_string(data);
}

CAMLprim value ocaml_musicbrainz_get_id_from_url(value mb, value url)
{
  char id[64];

  mb_GetIDFromURL(Mb_val(mb), String_val(url), id, 64);

  return caml_copy_string(id);
}

CAMLprim value ocaml_get_mp3_info(value mb, value fname)
{
  CAMLparam2(mb, fname);
  CAMLlocal1(ans);
  int duration, bitrate, stereo, samplerate;

  cerr(mb_GetMP3Info(Mb_val(mb), String_val(fname), &duration, &bitrate, &stereo, &samplerate));

  ans = caml_alloc_tuple(4);
  Store_field(ans, 0, Val_int(duration));
  Store_field(ans, 1, Val_int(bitrate));
  Store_field(ans, 2, Val_int(stereo));
  Store_field(ans, 3, Val_int(samplerate));
  CAMLreturn(ans);
}

/***** Queries *****/
CAMLprim value ocaml_musicbrainz_find_artist_by_name(value unit)
{
  return caml_copy_string(MBQ_FindArtistByName);
}

CAMLprim value ocaml_musicbrainz_track_info_from_TRM_id(value unit)
{
  return caml_copy_string(MBQ_TrackInfoFromTRMId);
}

CAMLprim value ocaml_musicbrainz_quick_track_info_from_track_id(value unit)
{
  return caml_copy_string(MBQ_QuickTrackInfoFromTrackId);
}

/***** TRM *****/

#define Trm_val(v) (*((trm_t*)Data_custom_val(v)))

static void finalize_trm(value trm)
{
  trm_Delete(Trm_val(trm));
}

static struct custom_operations trm_ops =
{
  "ocaml_trm_t",
  finalize_trm,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

CAMLprim value ocaml_trm_new(value unit)
{
  CAMLparam1(unit);
  CAMLlocal1(ans);

  trm_t trm = trm_New();
  ans = caml_alloc_custom(&trm_ops, sizeof(trm_t), 1, 0);
  Trm_val(ans) = trm;

  CAMLreturn(ans);
}

CAMLprim value ocaml_trm_set_proxy(value trm, value addr, value port)
{
  cerr(trm_SetProxy(Trm_val(trm), String_val(addr), Int_val(port)));

  return Val_unit;
}

CAMLprim value ocaml_trm_set_pcm_data_info(value trm, value freq, value chans, value bits)
{
  cerr(trm_SetPCMDataInfo(Trm_val(trm), Int_val(freq), Int_val(chans), Int_val(bits)));

  return Val_unit;
}

CAMLprim value ocaml_trm_set_song_length(value trm, value length)
{
  trm_SetSongLength(Trm_val(trm), Int_val(length));

  return Val_unit;
}

CAMLprim value ocaml_trm_generate_signature(value trm, value data, value offs, value len)
{
  int ret;
  /* TODO: offs + len < length(data) */

  ret = trm_GenerateSignature(Trm_val(trm), String_val(data) + Int_val(offs), Int_val(len));

  return Val_bool(ret);
}

CAMLprim value ocaml_trm_finalize_signature(value trm, value coll_id)
{
  /* TODO: coll_id */
  value ans = caml_alloc_string(17);

  cerr(trm_FinalizeSignature(Trm_val(trm), String_val(ans), NULL));

  return ans;
}

CAMLprim value ocaml_trm_convert_sig_to_ascii(value trm, value sig)
{
  char ascii_sig[37];

  if (caml_string_length(sig) != 17)
    caml_invalid_argument("sig should be 17 bytes long");

  trm_ConvertSigToASCII(Trm_val(trm), String_val(sig), ascii_sig);

  return caml_copy_string(ascii_sig);
}
