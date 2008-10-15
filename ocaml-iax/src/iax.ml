(* 
   Copyright 2003-2008 Savonet team

   This file is part of Ocaml-iax.

   Ocaml-iax is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   Ocaml-iax is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with Ocaml-iax; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*)
(*
  Libiax bindings for OCaml.

  @author Frank Spijkerman
  @author Romain Beauxis
*)

type session
type audio_format = 
  G723_1 | Gsm | Ulaw | Alaw | Mp3 | Adpcm |
  Slinear | Lpc10
       and
     image_format = 
  Jpeg | Png 
       and
     video_format = 
  H261 | H263
       and
     format = 
  Audio_format of audio_format | 
  Image_format of image_format | 
  Video_format of video_format
type connect_request = 
  { callerid : string;
    dnid     : string;
    context  : string;
    exten    : string;
    username : string;
    hostname : string;
    secret   : string;
    language : string;
    portno   : int;
    formats  : format list;
    version  : int
  }
      and
    transfer = 
  { newip   : string;
    newport : int
  }
      and
    authentification_method = Plain_text | Md5
      and
    authentication_request = 
  { authmethods : authentification_method list;
    challenge   : string;
    username    : string
  }
      and
    registration_status = Sucess_status | Reject_status | Timeout_status
      and 
    registration_reply = 
  { status   : registration_status;
    ourip    : string;
    callerid : string;
    ourport  : int;
    refresh  : bool
  } 
      and
    registration_request = 
  { server  : string;
    portno  : int;
    peer    : string;
    secret  : string;
    refresh : bool
  }  
      and
    authentication_reply = 
  { authmethod : authentification_method;
    replay     : string
  }
      and
    lag = 
  { lag    : int;
    jitter : int
  }
      and
    ping = 
  { ts    : int;
    seqno : int
  }
      and
    event_url = 
  { link : int;
    url  : string
  }
      and
    dialplan_reply = 
  { number      : string;
    exists      : bool;
    canexist    : bool;
    nonexistant : bool;
    ignorepat   : bool;
    expirey     : int
  }
      and
    event_type = 
 Connect of connect_request | Accept | Hangup of string | Reject of string |
 Voice of audio_format*string | Dtmf of char | Timeout | Lag_request of int |
 Lag_reply of lag | Ring | Ping of ping | Pong of ping | 
 Authentication_request of authentication_request | Authentication_reply of authentication_reply |
 Busy | Answer | Image of image_format*string | Registration_request of registration_request |
 Registration_reply of registration_reply | Url of event_url | 
 Url_load_complete | Transfer of transfer | Dialplan_request of string |
 Dialplan_reply of dialplan_reply | Dial of string | Quelch | Unquelch | Unlink |
 Link_rejection | Text of string
      and
    event = session*event_type

exception No_event
exception Malloc
exception Error

let _ =
  Callback.register_exception "iax_session_exn_no_event" No_event;
  Callback.register_exception "iax_session_exn_malloc" Malloc;
  Callback.register_exception "iax_session_exn_error" Error

external init : int -> int = "ocaml_iax_init"

(* Internal type for event data *)
type internal_data

(* From iax/frame.h *)
let xG723_1    = 1 lsl 0        (* G.723.1 compression *)
let xGsm       = 1 lsl 1        (* GSM compression *)
let xUlaw      = 1 lsl 2        (* Raw mu-law data (G.711) *)
let xAlaw      = 1 lsl 3        (* Raw A-law data (G.711) *)
let xMp3       = 1 lsl 4        (* MPEG-2 layer 3 *)
let xAdpcm     = 1 lsl 5        (* ADPCM (whose?) *)
let xSlinear   = 1 lsl 6        (* Raw 16-bit Signed Linear (8000 Hz) PCM *)
let xLpc10     = 1 lsl 7        (* LPC10, 180 samples/frame *)
let xMax_audio = 1 lsl 15       (* Maximum audio format *)
let xJpeg      = 1 lsl 16       (* JPEG Images *)
let xPng       = 1 lsl 17       (* PNG Images *)
let xH261      = 1 lsl 18       (* H.261 Video *)
let xH263      = 1 lsl 19       (* H.263 Video *)

let audio_format_of_int x = 
  match x with
    | y when y = xG723_1  -> G723_1
    | y when y = xGsm     -> Gsm
    | y when y = xUlaw    -> Ulaw
    | y when y = xAlaw    -> Alaw
    | y when y = xMp3     -> Mp3
    | y when y = xAdpcm   -> Adpcm
    | y when y = xSlinear -> Slinear
    | y when y = xLpc10   -> Lpc10
    | _        -> failwith "wrong audio format"

let int_of_audio_format x = 
  match x with
    | G723_1  -> xG723_1
    | Gsm     -> xGsm
    | Ulaw    -> xUlaw
    | Alaw    -> xAlaw
    | Mp3     -> xMp3
    | Adpcm   -> xAdpcm
    | Slinear -> xSlinear
    | Lpc10   -> xLpc10

let audio_formats_of_int x = 
  let l = ref [] in
  let f y = 
    if (x land y) <> 0 then true else false
  in
  if f xG723_1 then l := G723_1 :: !l;
  if f xGsm then l := Gsm :: !l;
  if f xUlaw then l := Ulaw :: !l;
  if f xAlaw then l := Alaw :: !l;
  if f xMp3 then l := Mp3 :: !l;
  if f xAdpcm then l := Adpcm :: !l;
  if f xSlinear then l := Slinear :: !l;
  if f xLpc10 then l :=  Lpc10 :: !l;
  if f xMax_audio then failwith "Wrong audio format: MAX_AUDIO";
  !l

let image_format_of_int x =
  match x with
    | y when y = xJpeg -> Jpeg
    | y when y = xPng  -> Png
    | _     -> failwith "wrong image format"

let int_of_image_format x =
  match x with
    | Jpeg -> xJpeg
    | Png  -> xPng

let image_formats_of_int x =
  let l = ref [] in
  let f y =
    if (x land y) <> 0 then true else false
  in
  if f xJpeg then l := Jpeg :: !l;
  if f xPng then l := Png :: !l;
  !l


let int_of_video_format x =
  match x with
    | H261 -> xH261
    | H263 -> xH263

let video_formats_of_int x =
  let l = ref [] in
  let f y =
    if (x land y) <> 0 then true else false
  in
  if f xH261 then l := H261 :: !l;
  if f xH263 then l := H263 :: !l;
  !l

let formats_of_int x = 
  (List.map (fun x -> Audio_format x) (audio_formats_of_int x)) @
  (List.map (fun x -> Image_format x) (image_formats_of_int x)) @
  (List.map (fun x -> Video_format x) (video_formats_of_int x))

let int_of_format x = 
  match x with
    | Audio_format x -> int_of_audio_format x
    | Video_format x -> int_of_video_format x
    | Image_format x -> int_of_image_format x

let int_of_formats l = 
  let ret = ref 0 in
  List.iter (fun x -> ret := !ret lor int_of_format x) l;
  !ret 

let xPlain_text = 1
let xMd5 = 2

let auth_method_of_int x = 
  match x with
    | x when x = xPlain_text -> Plain_text
    | x when x = xMd5 -> Md5
    | _ -> failwith "wrong auth method"

let int_of_auth_method x = 
  match x with
    | Plain_text -> xPlain_text
    | Md5 -> xMd5

let auth_methods_of_int x = 
  let l = ref [] in
  let f y =
    if (x land y) <> 0 then true else false
  in
  if f xPlain_text then l := Plain_text :: !l;
  if f xMd5 then l := Md5 :: !l;
  l

let int_of_auth_methods l = 
  let x = ref 0 in
  List.iter (fun y -> x := !x lor y) l;
  !x

let _ =
  Callback.register "caml_iax_formats_of_int" formats_of_int;
  Callback.register "caml_iax_int_of_formats" int_of_formats;
  Callback.register "caml_iax_image_format_of_int" image_format_of_int;
  Callback.register "caml_iax_int_of_image_format" int_of_image_format;
  Callback.register "caml_iax_audio_format_of_int" audio_format_of_int;
  Callback.register "caml_iax_int_of_audio_format" int_of_audio_format;
  Callback.register "caml_iax_auth_methods_of_int" auth_methods_of_int;
  Callback.register "caml_iax_int_of_auth_methods" int_of_auth_methods

let int_of_event_type e = 
  match e with
    | Connect _     -> 0
    | Accept        -> 1
    | Hangup _      -> 2
    | Reject _      -> 3
    | Voice _       -> 4
    | Dtmf _        -> 5
    | Timeout       -> 6
    | Lag_request _ -> 7
    | Lag_reply _   -> 8
    | Ring          -> 9
    | Ping _        -> 10
    | Pong _        -> 11
    | Busy          -> 12
    | Answer        -> 13
    | Image _       -> 14
    | Authentication_request _ -> 15
    | Authentication_reply _   -> 16
    | Registration_request _   -> 17
    | Registration_reply _     -> 18
    | Url _                    -> 19
    | Url_load_complete        -> 20
    | Transfer _               -> 21
    | Dialplan_request _       -> 22
    | Dialplan_reply _         -> 23
    | Dial _                   -> 24
    | Quelch                   -> 25
    | Unquelch                 -> 26
    | Unlink                   -> 27
    | Link_rejection           -> 28
    | Text _                   -> 29

let event_of_internal_data (i,session,data) = 
  let f = Obj.magic in
  session,
  match i with
    | 0 -> Connect (f data)
    | 1 -> Accept
    | 2 -> Hangup (f data)
    | 3	-> Reject (f data)
    | 4	-> let x = f data in
           Voice (fst(x),snd(x))
    | 5	-> Dtmf (f data)
    | 6	-> Timeout 
    | 7	-> Lag_request (f data)
    | 8	-> Lag_reply (f data)
    | 9	-> Ring
    | 10 -> Ping (f data)
    | 11 -> Pong (f data)
    | 12 -> Busy
    | 13 -> Answer
    | 14 -> let x = f data in
            Image (fst(x),snd(x))
    | 15 -> Authentication_request (f data)
    | 16 -> Authentication_reply (f data)
    | 17 -> Registration_request (f data)
    | 18 -> Registration_reply (f data)
    | 19 -> Url (f data)
    | 20 -> Url_load_complete
    | 21 -> Transfer (f data)
    | 22 -> Dialplan_request (f data)
    | 23 -> Dialplan_reply (f data)
    | 24 -> Dial (f data)
    | 25 -> Quelch
    | 26 -> Unquelch
    | 27 -> Unlink
    | 28 -> Link_rejection
    | 29 -> Text (f data)
    | _  -> failwith "Unknown event type.."

let internal_data_of_event_type data = 
  let f = Obj.magic in
  match data with
    | Connect x -> f x
    | Accept -> f ()
    | Hangup x -> f x
    | Reject x -> f x
    | Voice (x,y) -> f (x,y)
    | Dtmf x -> f x
    | Timeout -> f () 
    | Lag_request x -> f x
    | Lag_reply x -> f x
    | Ring -> f ()
    | Ping x -> f x
    | Pong x -> f x
    | Busy -> f ()
    | Answer -> f ()
    | Image (x,y) -> f (x,y)
    | Authentication_request x -> f x
    | Authentication_reply x -> f x
    | Registration_request x -> f x
    | Registration_reply x -> f x
    | Url x -> f x
    | Url_load_complete -> f ()
    | Transfer x -> f x
    | Dialplan_request x -> f x
    | Dialplan_reply x -> f x
    | Dial x -> f x
    | Quelch -> f ()
    | Unquelch -> f ()
    | Unlink -> f ()
    | Link_rejection -> f ()
    | Text x -> f x

external session_new : unit -> session = "ocaml_iax_session_new"
external get_fd : unit -> Unix.file_descr = "ocaml_iax_get_fd"
external time_to_next_event : unit -> int = "ocaml_iax_time_to_next_event"
external do_event : session -> int -> internal_data -> unit = "ocaml_iax_do_event"
let do_event (s,e) =
  do_event s (int_of_event_type e) (internal_data_of_event_type e)
external get_event : bool -> int*session*internal_data = "ocaml_iax_get_event"
let get_event b = 
  event_of_internal_data (get_event b)

external auth_reply : session -> string -> string -> int -> int = "ocaml_iax_auth_reply"

external set_formats : int -> unit = "ocaml_iax_set_formats"
let set_formats l = 
  let x = ref 0 in
  let int_of_format x = 
    match x with
      | Audio_format y -> int_of_audio_format y
      | Video_format y -> int_of_video_format y
      | Image_format y -> int_of_image_format y
  in
  List.iter (fun y -> x := !x lor (int_of_format y)) l;
  set_formats !x

external register : session -> string -> string -> string -> int -> unit = "ocaml_iax_register"

external lag_request : session -> unit = "ocaml_iax_lag_request"
