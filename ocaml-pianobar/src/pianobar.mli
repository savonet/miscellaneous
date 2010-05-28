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

module Http_ocamlnet : Http_t

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

module Piano_generic (Http : Http_t) : Piano_t

module Piano : Piano_t

