/*
  Copyright 2003-2008 Savonet team

  This file is part of Ocaml-pianobar.

  Ocaml-pianobar is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  Ocaml-pianobar is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Ocaml-pianobar; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/custom.h>
#include <caml/callback.h>

#include <pianobar/piano.h>

#include <string.h>

CAMLprim value caml_pianobar_host(value unit) 
{
  CAMLparam0();
  CAMLreturn(caml_copy_string(PIANO_RPC_HOST));
}

CAMLprim value caml_pianobar_port(value unit) 
{
  CAMLparam0();
  CAMLreturn(caml_copy_string(PIANO_RPC_PORT));
}

CAMLprim value caml_pianobar_int_of_define(value d)
{
  CAMLparam1(d);
  char *s = String_val(d);

  if (!strcmp(s,"PIANO_RATE_NONE"))
    CAMLreturn(Val_int(PIANO_RATE_NONE));
  if (!strcmp(s,"PIANO_RATE_LOVE"))
    CAMLreturn(Val_int(PIANO_RATE_LOVE));
  if (!strcmp(s,"PIANO_RATE_BAN"))
    CAMLreturn(Val_int(PIANO_RATE_BAN));
  if (!strcmp(s,"PIANO_AF_UNKNOWN"))
    CAMLreturn(Val_int(PIANO_AF_UNKNOWN));
  if (!strcmp(s,"PIANO_AF_AACPLUS"))
    CAMLreturn(Val_int(PIANO_AF_AACPLUS));
  if (!strcmp(s,"PIANO_AF_MP3"))
    CAMLreturn(Val_int(PIANO_AF_MP3));
  if (!strcmp(s,"PIANO_AF_MP3_HI"))
    CAMLreturn(Val_int(PIANO_AF_MP3_HI));
  if (!strcmp(s,"PIANO_REQUEST_LOGIN"))
    CAMLreturn(Val_int(PIANO_REQUEST_LOGIN));
  if (!strcmp(s,"PIANO_REQUEST_GET_STATIONS"))
    CAMLreturn(Val_int(PIANO_REQUEST_GET_STATIONS));
  if (!strcmp(s,"PIANO_REQUEST_GET_PLAYLIST"))
    CAMLreturn(Val_int(PIANO_REQUEST_GET_PLAYLIST));
  if (!strcmp(s,"PIANO_REQUEST_RATE_SONG"))
    CAMLreturn(Val_int(PIANO_REQUEST_RATE_SONG));
  if (!strcmp(s,"PIANO_REQUEST_ADD_FEEDBACK"))
    CAMLreturn(Val_int(PIANO_REQUEST_ADD_FEEDBACK));
  if (!strcmp(s,"PIANO_REQUEST_MOVE_SONG"))
    CAMLreturn(Val_int(PIANO_REQUEST_MOVE_SONG));
  if (!strcmp(s,"PIANO_REQUEST_RENAME_STATION"))
    CAMLreturn(Val_int(PIANO_REQUEST_RENAME_STATION));
  if (!strcmp(s,"PIANO_REQUEST_DELETE_STATION"))
    CAMLreturn(Val_int(PIANO_REQUEST_DELETE_STATION));
  if (!strcmp(s,"PIANO_REQUEST_SEARCH"))
    CAMLreturn(Val_int(PIANO_REQUEST_SEARCH));
  if (!strcmp(s,"PIANO_REQUEST_CREATE_STATION"))
    CAMLreturn(Val_int(PIANO_REQUEST_CREATE_STATION));
  if (!strcmp(s,"PIANO_REQUEST_ADD_SEED"))
    CAMLreturn(Val_int(PIANO_REQUEST_ADD_SEED));
  if (!strcmp(s,"PIANO_REQUEST_ADD_TIRED_SONG"))
    CAMLreturn(Val_int(PIANO_REQUEST_ADD_TIRED_SONG));
  if (!strcmp(s,"PIANO_REQUEST_SET_QUICKMIX"))
    CAMLreturn(Val_int(PIANO_REQUEST_SET_QUICKMIX));
  if (!strcmp(s,"PIANO_REQUEST_GET_GENRE_STATIONS"))
    CAMLreturn(Val_int(PIANO_REQUEST_GET_GENRE_STATIONS));
  if (!strcmp(s,"PIANO_REQUEST_TRANSFORM_STATION"))
    CAMLreturn(Val_int(PIANO_REQUEST_TRANSFORM_STATION));
  if (!strcmp(s,"PIANO_REQUEST_EXPLAIN"))
    CAMLreturn(Val_int(PIANO_REQUEST_EXPLAIN));
  if (!strcmp(s,"PIANO_REQUEST_GET_SEED_SUGGESTIONS"))
    CAMLreturn(Val_int(PIANO_REQUEST_GET_SEED_SUGGESTIONS));
  if (!strcmp(s,"PIANO_REQUEST_BOOKMARK_SONG"))
    CAMLreturn(Val_int(PIANO_REQUEST_BOOKMARK_SONG));
  if (!strcmp(s,"PIANO_REQUEST_BOOKMARK_ARTIST"))
    CAMLreturn(Val_int(PIANO_REQUEST_BOOKMARK_ARTIST));
  if (!strcmp(s,"PIANO_RET_ERR"))
    CAMLreturn(Val_int(PIANO_RET_ERR));
  if (!strcmp(s,"PIANO_RET_OK"))
    CAMLreturn(Val_int(PIANO_RET_OK));
  if (!strcmp(s,"PIANO_RET_XML_INVALID"))
    CAMLreturn(Val_int(PIANO_RET_XML_INVALID));
  if (!strcmp(s,"PIANO_RET_AUTH_TOKEN_INVALID"))
    CAMLreturn(Val_int(PIANO_RET_AUTH_TOKEN_INVALID));
  if (!strcmp(s,"PIANO_RET_AUTH_USER_PASSWORD_INVALID"))
    CAMLreturn(Val_int(PIANO_RET_AUTH_USER_PASSWORD_INVALID));
  if (!strcmp(s,"PIANO_RET_CONTINUE_REQUEST"))
    CAMLreturn(Val_int(PIANO_RET_CONTINUE_REQUEST));
  if (!strcmp(s,"PIANO_RET_NOT_AUTHORIZED"))
    CAMLreturn(Val_int(PIANO_RET_NOT_AUTHORIZED));
  if (!strcmp(s,"PIANO_RET_PROTOCOL_INCOMPATIBLE"))
    CAMLreturn(Val_int(PIANO_RET_PROTOCOL_INCOMPATIBLE));
  if (!strcmp(s,"PIANO_RET_READONLY_MODE"))
    CAMLreturn(Val_int(PIANO_RET_READONLY_MODE));
  if (!strcmp(s,"PIANO_RET_STATION_CODE_INVALID"))
    CAMLreturn(Val_int(PIANO_RET_STATION_CODE_INVALID));
  if (!strcmp(s,"PIANO_RET_IP_REJECTED"))
    CAMLreturn(Val_int(PIANO_RET_IP_REJECTED));
  if (!strcmp(s,"PIANO_RET_STATION_NONEXISTENT"))
    CAMLreturn(Val_int(PIANO_RET_STATION_NONEXISTENT));
  if (!strcmp(s,"PIANO_RET_OUT_OF_MEMORY"))
    CAMLreturn(Val_int(PIANO_RET_OUT_OF_MEMORY));
  if (!strcmp(s,"PIANO_RET_OUT_OF_SYNC"))
    CAMLreturn(Val_int(PIANO_RET_OUT_OF_SYNC));
  if (!strcmp(s,"PIANO_RET_PLAYLIST_END"))
    CAMLreturn(Val_int(PIANO_RET_PLAYLIST_END));
  if (!strcmp(s,"PIANO_RET_QUICKMIX_NOT_PLAYABLE"))
    CAMLreturn(Val_int(PIANO_RET_QUICKMIX_NOT_PLAYABLE));
  
  caml_failwith("unknown value");
}

static value val_of_station(PianoStation_t *s) 
{
  CAMLparam0();
  CAMLlocal1(ret);
  int i = 0;
  ret = caml_alloc_tuple(5);
  Store_field(ret,i++,Val_bool(s->isCreator));
  Store_field(ret,i++,Val_bool(s->isQuickMix));
  Store_field(ret,i++,Val_bool(s->useQuickMix));
  Store_field(ret,i++,caml_copy_string(s->name));
  Store_field(ret,i++,caml_copy_string(s->id));

  CAMLreturn(ret);
}

static PianoStation_t *station_of_val(PianoStation_t *s, value v)
{
  int i = 0;
  s->isCreator = Int_val(Field(v, i++));
  s->isQuickMix = Int_val(Field(v, i++));
  s->useQuickMix = Int_val(Field(v, i++));
  s->name = String_val(Field(v, i++));
  s->id = String_val(Field(v, i++));
  s->next = NULL;

  return s;
}

static value val_of_song(PianoSong_t *s)
{
  CAMLparam0();
  CAMLlocal1(ret);
  int i = 0;
  ret = caml_alloc_tuple(14);
  Store_field(ret,i++,caml_copy_string(s->artist));
  Store_field(ret,i++,caml_copy_string(s->artistMusicId));
  Store_field(ret,i++,caml_copy_string(s->matchingSeed));
  Store_field(ret,i++,caml_copy_double(s->fileGain));
  Store_field(ret,i++,Val_int(s->rating));
  Store_field(ret,i++,caml_copy_string(s->stationId));
  Store_field(ret,i++,caml_copy_string(s->album));
  Store_field(ret,i++,caml_copy_string(s->userSeed));
  Store_field(ret,i++,caml_copy_string(s->audioUrl));
  Store_field(ret,i++,caml_copy_string(s->musicId));
  Store_field(ret,i++,caml_copy_string(s->title));
  Store_field(ret,i++,caml_copy_string(s->focusTraitId));
  Store_field(ret,i++,caml_copy_string(s->identity));
  Store_field(ret,i++,Val_int(s->audioFormat));

  CAMLreturn(ret);
}

#define Handle_val(v) (*((PianoHandle_t **)Data_custom_val(v)))

static void finalize_handle(value v)
{
  PianoHandle_t *handle = Handle_val(v);
  PianoDestroy(handle);
  free(handle);
}

static struct custom_operations handle_ops =
{
  "caml_pianobar_handle",
  finalize_handle,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

CAMLprim value caml_pianobar_init(value unit) 
{
  CAMLparam0();
  CAMLlocal1(ans);

  PianoHandle_t *handle = malloc(sizeof(PianoHandle_t));
  if (handle == NULL)
    caml_raise_out_of_memory();

  PianoInit(handle);

  ans = caml_alloc_custom(&handle_ops, sizeof(PianoHandle_t *), 1, 0);
  Handle_val(ans) = handle;

  CAMLreturn(ans);
}

CAMLprim value caml_pianobar_string_or_error(value er)
{
  CAMLparam0();
  CAMLreturn(caml_copy_string(PianoErrorToStr(Int_val(er))));
}

static int process_req(PianoHandle_t *h, void *reqData, PianoRequestType_t x)
{
  CAMLparam0();
  CAMLlocal3(url,data,ret);
  int err = PIANO_RET_CONTINUE_REQUEST;
  PianoRequest_t req;
  req.data = reqData;
  req.type = x;

  do {
    err = PianoRequest(h,&req,x);
    if (err != PIANO_RET_OK) {
      PianoDestroyRequest(&req); 
      caml_callback(*caml_named_value("caml_pianobar_raise"),Val_int(err));
    }

    url = caml_copy_string(req.urlPath);
    data = caml_copy_string(req.postData);
    ret = caml_callback2_exn(*caml_named_value("caml_pianobar_process_req"),url,data);
    if (Is_exception_result(ret))
    {
      PianoDestroyRequest(&req);
      caml_raise(Extract_exception(ret));
    }
    req.responseData = String_val(ret);
    err = PianoResponse(h,&req);
    PianoDestroyRequest (&req);
  } while (err == PIANO_RET_CONTINUE_REQUEST);

  CAMLreturn(err);
}

CAMLprim value caml_pianobar_login_req(value _h, value user, value password)
{
  CAMLparam3(_h,user,password);
  CAMLlocal1(ret);
  int err;
  PianoRequestDataLogin_t reqData;
  PianoHandle_t *h = Handle_val(_h);  

  reqData.user = String_val(user);
  reqData.password = String_val(password);

  err = process_req(h,(void *) &reqData,PIANO_REQUEST_LOGIN);
  if (err != PIANO_RET_OK) 
    caml_callback(*caml_named_value("caml_pianobar_raise"),Val_int(err));
  CAMLreturn(Val_unit);
}

CAMLprim value caml_pianobar_get_stations(value _h, value ret)
{
  CAMLparam2(_h,ret);
  PianoHandle_t *h = Handle_val(_h);
  PianoStation_t *s;
  int err;
 
  if (h->stations == NULL) {
    err = process_req(h,NULL,PIANO_REQUEST_GET_STATIONS);
    if (err != PIANO_RET_OK)
      caml_callback(*caml_named_value("caml_pianobar_raise"),Val_int(err));
  }

  s = h->stations;
  while (s != NULL) {
    ret = caml_callback2(*caml_named_value("caml_pianobar_add_elem"),val_of_station(s),ret);
    s = s->next;  
  }

  CAMLreturn(ret);
}

CAMLprim value caml_pianobar_get_playlist(value _h, value _format, value _station, value ret)
{
  CAMLparam3(_h,ret,_station);
  PianoHandle_t *h = Handle_val(_h);
  PianoRequestDataGetPlaylist_t reqData;
  PianoStation_t s;
  PianoSong_t *song;
  int err;
 
  station_of_val(&s,_station);
  reqData.station = &s;
  reqData.format = Int_val(_format);
  reqData.retPlaylist = NULL;

  err = process_req(h,(void *)&reqData,PIANO_REQUEST_GET_PLAYLIST);
  if (err != PIANO_RET_OK) {
    PianoDestroyPlaylist(reqData.retPlaylist);
    caml_callback(*caml_named_value("caml_pianobar_raise"),Val_int(err));
  }

  song = reqData.retPlaylist;
  while (song != NULL) {
    ret = caml_callback2(*caml_named_value("caml_pianobar_add_elem"),val_of_song(song),ret);
    song = song->next;
  }

  PianoDestroyPlaylist(reqData.retPlaylist);

  CAMLreturn(ret);
}

