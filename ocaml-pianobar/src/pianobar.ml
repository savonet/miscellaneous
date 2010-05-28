(*****************************************************************************

  Liquidsoap, a programmable audio stream generator.
  Copyright 2003-2010 Savonet team

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details, fully stated in the COPYING
  file at the root of the liquidsoap distribution.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

 *****************************************************************************)

(* An interface to libpianobar, which allows access to Pandora radios. *)

(** This is the type of Http request API
  * that the modules require. *)
module type Http_t =
sig
  exception Http of string

  val timeout : float ref
  val request : ?port:int -> host:string -> url:string -> 
                request:string -> unit -> string
end

module Http_ocamlnet =
struct
  exception Http of string

  let timeout = ref 5.

  let request ?(port=80) ~host ~url ~request () =
    let timeout = !timeout in 
    let call = new Http_client.post_call in
    let pipeline = new Http_client.pipeline in
    pipeline#set_options 
      { pipeline#get_options with 
          Http_client.connection_timeout = timeout 
      } ;
    let body = call#request_body in
    call#set_request_uri (Printf.sprintf "http://%s:%d%s" host port url) ;
    body#set_value request ; 
    call#set_request_body body ;
    let http_headers = call#request_header `Base in
    http_headers#update_field 
       "Content-length" 
       (string_of_int (String.length request));
    http_headers#update_field       
       "Content-type" "text/xml" ;
    http_headers#update_field       
       "User-agent"
       (Printf.sprintf "ocaml-pianobar/%s" Pianobar_constants.version) ; 
    call#set_request_header http_headers ;
    pipeline#add call ;
    try
      pipeline#run () ;
      call#response_body#value
    with
      | Http_client.Http_protocol e 
      | e -> 
         pipeline#reset() ; 
         raise (Http  (Printexc.to_string e))
end

module type Piano_t = 
sig
  type t

  val pianobar_host : string
  val pianobar_port : int

  type station = 
    { 
      is_creator   : bool;
      is_quickmix  : bool;
      use_quickmix : bool;
      station_name : string;
      station_id   : int; 
    }

  type rating = Love | Ban

  type audio_format = Aac_plus | Mp3 | Mp3_high

  type artist =
    {
      artist_name     : string;
      artist_music_id : int;    
      artist_score    : int;
    }

  type song = 
    {
      artist               : string;
      song_artist_music_id : string;
      matching_seed        : string;
      file_gain            : float;
      song_rating          : rating option;
      song_station_id      : int;
      album                : string;
      user_seed            : string;
      audio_url            : string;
      music_id             : string;
      title                : string;
      focus_trait_id       : string;
      idendity             : string;
      audio_format         : audio_format option;
    }

  type genre = 
    {
      genre_name    : string;
      genre_station : station;
    }

  type playlist = 
    {
      playlist_station      : station ;
      playlist_audio_format : audio_format option;
      playlist_song         : song;
    }

  type feedback = 
    {
      feedback_station_id     :  int;
      feedback_music_id       :  int;
      feedback_matching_seed  :  string;
      feedback_user_seed      :  string;
      feedback_focus_trait_id :  int;
      feedback_rating         :  rating option;
    }

  type error = 
          Error                      |
          Xml_invalid                |
          Auth_token_invalid         |
          Auth_user_password_invalid |
          Continue_request           |
          Not_authorized             |
          Incompatible_protocol      |
          Readonly_mode              |
          Station_code_invalid       |
          Ip_rejected                |
          Station_nonexistent        |
          Out_of_memory              |
          Out_of_sync                |
          Playlist_end               |
          Quickmix_not_playable      | 
          Http of string

  exception Error of error

  val init : unit -> t

  val string_of_error : error -> string

  val login : user:string -> password:string -> t -> unit

  val get_stations : t -> station list

  val get_playlist : format:audio_format -> station:station -> t -> song list
end

module Piano_generic(Http : Http_t) = 
struct
  type t

  external get_host  : unit -> string = "caml_pianobar_host"
  external get_port  : unit -> string = "caml_pianobar_port"

  let pianobar_host = get_host ()
  let pianobar_port = int_of_string (get_port ())

  external int_of_define : string -> int = "caml_pianobar_int_of_define"

  type station = 
    { 
      is_creator   : bool;
      is_quickmix  : bool;
      use_quickmix : bool;
      station_name : string;
      station_id   : int; 
    }

  type station_priv =
    {
      _is_creator   : bool;
      _is_quickmix  : bool;
      _use_quickmix : bool;
      _station_name : string;
      _station_id   : string;
    }

  let station_of_station_priv x =
    {
      is_creator = x._is_creator;
      is_quickmix = x._is_quickmix;
      use_quickmix = x._use_quickmix;
      station_name = x._station_name;
      station_id = int_of_string x._station_id;
    }
 
  let station_priv_of_station x =
    {
      _is_creator = x.is_creator;
      _is_quickmix = x.is_quickmix;
      _use_quickmix = x.use_quickmix;
      _station_name = x.station_name;
      _station_id = Printf.sprintf "%d" x.station_id;
    }
 
  type rating = Love | Ban

  let int_of_rating x =
    match x with
      | None -> int_of_define "PIANO_RATE_NONE"
      | Some Love -> int_of_define "PIANO_RATE_LOVE"
      | Some Ban -> int_of_define "PIANO_RATE_BAN"

  let rating_of_int x = 
    match x with
      | x when x = int_of_define "PIANO_RATE_NONE" 
           -> None
      | x when x = int_of_define "PIANO_RATE_LOVE"
           -> Some Love
      | x when x = int_of_define "PIANO_RATE_BAN"
           -> Some Ban
      | _ -> raise Not_found

  type audio_format = Aac_plus | Mp3 | Mp3_high

  let int_of_audio_format x =
    let f = int_of_define in
    match x with
      | None -> f "PIANO_AF_UNKNOWN"
      | Some Aac_plus -> f "PIANO_AF_AACPLUS"
      | Some Mp3 -> f "PIANO_AF_MP3"
      | Some Mp3_high -> f "PIANO_AF_MP3_HI"

  let audio_format_of_int x = 
    let f = int_of_define in
    match x with
      | x when x = f "PIANO_AF_UNKNOWN"
           -> None
      | x when x = f "PIANO_AF_AACPLUS"
           -> Some Aac_plus
      | x when x = f "PIANO_AF_MP3"
           -> Some Mp3
      | x when x = f "PIANO_AF_MP3_HI"
           -> Some Mp3_high
      | _ -> raise Not_found

  type artist =
    {
      artist_name     : string;
      artist_music_id : int;    
      artist_score    : int;
    }

  type song = 
    {
      artist                : string;
      song_artist_music_id  : string;
      matching_seed         : string;
      file_gain             : float;
      song_rating           : rating option;
      song_station_id       : int;
      album                 : string;
      user_seed             : string;
      audio_url             : string;
      music_id              : string;
      title                 : string;
      focus_trait_id        : string;
      idendity              : string;
      audio_format          : audio_format option;
    }

  type song_priv = 
    {
      _artist               : string;
      _song_artist_music_id : string;
      _matching_seed        : string;
      _file_gain            : float;
      _song_rating          : int;
      _song_station_id      : string;
      _album                : string;
      _user_seed            : string;
      _audio_url            : string;
      _music_id             : string;
      _title                : string;
      _focus_trait_id       : string;
      _idendity             : string;
      _audio_format         : int;
    }

  let song_of_song_priv x = 
    {
      artist = x._artist;
      song_artist_music_id = x._song_artist_music_id;
      matching_seed = x._matching_seed;
      file_gain = x._file_gain;
      song_rating = rating_of_int x._song_rating;
      song_station_id = int_of_string x._song_station_id;
      album = x._album;
      user_seed = x._user_seed;
      audio_url = x._audio_url;
      music_id = x._music_id;
      title = x._title;
      focus_trait_id = x._focus_trait_id;
      idendity = x._idendity;
      audio_format = audio_format_of_int x._audio_format;
    }

  let song_priv_of_song x = 
    {
      _artist = x.artist;
      _song_artist_music_id = x.song_artist_music_id;
      _matching_seed = x.matching_seed;
      _file_gain = x.file_gain;
      _song_rating = int_of_rating x.song_rating;
      _song_station_id = Printf.sprintf "%d" x.song_station_id;
      _album = x.album;
      _user_seed = x.user_seed;
      _audio_url = x.audio_url;
      _music_id = x.music_id;
      _title = x.title;
      _focus_trait_id = x.focus_trait_id;
      _idendity = x.idendity;
      _audio_format = int_of_audio_format x.audio_format;
    }

  type genre = 
    {
      genre_name    : string;
      genre_station : station;
    }

  type playlist = 
    {
      playlist_station      : station ;
      playlist_audio_format : audio_format option;
      playlist_song         : song;
    }

  type playlist_priv =
    {
      _playlist_station      : station ;
      _playlist_audio_format : int;
      _playlist_song         : song_priv;
    }

  let playlist_of_playlist_priv x = 
    {
      playlist_station = x._playlist_station;
      playlist_audio_format = audio_format_of_int x._playlist_audio_format;
      playlist_song = song_of_song_priv x._playlist_song;
    }

  let playlist_priv_of_playlist x = 
    {
      _playlist_station = x.playlist_station;
      _playlist_audio_format = int_of_audio_format x.playlist_audio_format;
      _playlist_song = song_priv_of_song x.playlist_song;
    }

  type feedback = 
    {
      feedback_station_id     :  int;
      feedback_music_id       :  int;
      feedback_matching_seed  :  string;
      feedback_user_seed      :  string;
      feedback_focus_trait_id :  int;
      feedback_rating         :  rating option;
    }

  type feedback_priv =
    {
      _feedback_station_id     :  int;
      _feedback_music_id       :  int;
      _feedback_matching_seed  :  string;
      _feedback_user_seed      :  string;
      _feedback_focus_trait_id :  int;
      _feedback_rating         :  int;
    }

  let feedback_of_feedback_priv x = 
    {
      feedback_station_id = x._feedback_station_id;
      feedback_music_id = x._feedback_music_id;
      feedback_matching_seed = x._feedback_matching_seed;
      feedback_user_seed = x._feedback_user_seed;
      feedback_focus_trait_id = x._feedback_focus_trait_id;
      feedback_rating = rating_of_int x._feedback_rating;
    }

  let feedback_priv_of_feedback x = 
    {
      _feedback_station_id = x.feedback_station_id;
      _feedback_music_id = x.feedback_music_id;
      _feedback_matching_seed = x.feedback_matching_seed;
      _feedback_user_seed = x.feedback_user_seed;
      _feedback_focus_trait_id = x.feedback_focus_trait_id;
      _feedback_rating = int_of_rating x.feedback_rating;
    }

  type error = 
          Error                      |
          Xml_invalid                |
          Auth_token_invalid         |
          Auth_user_password_invalid |
          Continue_request           |
          Not_authorized             |
          Incompatible_protocol      |
          Readonly_mode              |
          Station_code_invalid       |
          Ip_rejected                |
          Station_nonexistent        |
          Out_of_memory              |
          Out_of_sync                |
          Playlist_end               |
          Quickmix_not_playable      |
          Http of string

  let error_of_int x = 
    let f = int_of_define in
    match x with
      | x when x = f "PIANO_RET_ERR" -> Error
      | x when x = f "PIANO_RET_XML_INVALID" -> Xml_invalid 
      | x when x = f "PIANO_RET_AUTH_TOKEN_INVALID" -> Auth_token_invalid 
      | x when x = f "PIANO_RET_AUTH_USER_PASSWORD_INVALID" -> Auth_user_password_invalid 
      | x when x = f "PIANO_RET_CONTINUE_REQUEST" -> Continue_request 
      | x when x = f "PIANO_RET_NOT_AUTHORIZED" -> Not_authorized 
      | x when x = f "PIANO_RET_PROTOCOL_INCOMPATIBLE" -> Incompatible_protocol
      | x when x = f "PIANO_RET_READONLY_MODE" -> Readonly_mode 
      | x when x = f "PIANO_RET_STATION_CODE_INVALID" -> Station_code_invalid 
      | x when x = f "PIANO_RET_IP_REJECTED" -> Ip_rejected 
      | x when x = f "PIANO_RET_STATION_NONEXISTENT" -> Station_nonexistent 
      | x when x = f "PIANO_RET_OUT_OF_MEMORY" -> Out_of_memory 
      | x when x = f "PIANO_RET_OUT_OF_SYNC" -> Out_of_sync 
      | x when x = f "PIANO_RET_PLAYLIST_END" -> Playlist_end 
      | x when x = f "PIANO_RET_QUICKMIX_NOT_PLAYABLE" -> Quickmix_not_playable
      | _ -> raise Not_found

  let int_of_error x = 
    let f = int_of_define in
    match x with
      | Http _ -> raise Not_found
      | Error -> f "PIANO_RET_ERR"
      | Xml_invalid -> f "PIANO_RET_XML_INVALID"
      | Auth_token_invalid -> f "PIANO_RET_AUTH_TOKEN_INVALID"
      | Auth_user_password_invalid -> f "PIANO_RET_AUTH_USER_PASSWORD_INVALID"
      | Continue_request -> f "PIANO_RET_CONTINUE_REQUEST"
      | Not_authorized -> f "PIANO_RET_NOT_AUTHORIZED"
      | Incompatible_protocol -> f "PIANO_RET_PROTOCOL_INCOMPATIBLE"
      | Readonly_mode -> f "PIANO_RET_READONLY_MODE"
      | Station_code_invalid -> f "PIANO_RET_STATION_CODE_INVALID"
      | Ip_rejected -> f "PIANO_RET_IP_REJECTED"
      | Station_nonexistent -> f "PIANO_RET_STATION_NONEXISTENT"
      | Out_of_memory -> f "PIANO_RET_OUT_OF_MEMORY"
      | Out_of_sync -> f "PIANO_RET_OUT_OF_SYNC"
      | Playlist_end -> f "PIANO_RET_PLAYLIST_END"
      | Quickmix_not_playable -> f "PIANO_RET_QUICKMIX_NOT_PLAYABLE"

  exception Error of error

  let raise_error x = 
     raise (Error (error_of_int x))

  let () = 
    Callback.register "caml_pianobar_raise" raise_error

  (* We wrap Http.request to raise an internal exception. *)
  let http_request ~url ~request () =
    try
      Http.request ~port:pianobar_port ~host:pianobar_host 
                   ~url ~request ()
    with
      | Http.Http s -> raise (Error (Http s))
  
  external init : unit -> t = "caml_pianobar_init"

  external string_of_error :  int -> string = "caml_pianobar_string_or_error"

  let string_of_error x = 
    match x with
      | Http s -> Printf.sprintf "Http error: %s" s
      | x -> string_of_error (int_of_error x)

  let process_req url request =
    http_request ~url ~request ()

  let () =
    Callback.register "caml_pianobar_process_req" process_req

  external login : t -> string -> string -> unit = "caml_pianobar_login_req"

  let login ~user ~password t = login t user password

  let add_elem x l = x::l

  let () =
    Callback.register "caml_pianobar_add_elem" add_elem

  external get_stations : t -> station_priv list -> station_priv list = "caml_pianobar_get_stations"

  let get_stations t = 
    List.map station_of_station_priv (List.rev (get_stations t []))

  external get_playlist : t -> int -> station_priv -> song_priv list -> song_priv list = "caml_pianobar_get_playlist"

  let get_playlist ~format ~station t = 
    let ret = get_playlist t (int_of_audio_format (Some format)) (station_priv_of_station station) [] in
    List.map song_of_song_priv (List.rev ret)

end

module Piano = Piano_generic(Http_ocamlnet)

