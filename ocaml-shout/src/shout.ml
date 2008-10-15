(* 
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
*)
(*
  Libshout 2 bindings for OCaml.

  @author Samuel Mimram
*)

(* $Id$ *)

type shout

type data_format = Format_vorbis | Format_mp3

type protocol = Protocol_http | Protocol_xaudiocast | Protocol_icy

exception Insane
exception No_connect
exception No_login
exception Socket
exception Malloc
exception Metadata
exception Connected
exception Unconnected
exception Unsupported
exception Send_error

let _ =
  Callback.register_exception "shout_exn_insane" Insane;
  Callback.register_exception "shout_exn_no_connect" No_connect;
  Callback.register_exception "shout_exn_no_login" No_login;
  Callback.register_exception "shout_exn_socket" Socket;
  Callback.register_exception "shout_exn_malloc" Malloc;
  Callback.register_exception "shout_exn_metadata" Metadata;
  Callback.register_exception "shout_exn_connected" Connected;
  Callback.register_exception "shout_exn_unconnected" Unconnected;
  Callback.register_exception "shout_exn_unsupported" Unsupported

external init : unit -> unit = "ocaml_shout_init"

external shutdown : unit -> unit = "ocaml_shout_shutdown"

external version : unit -> string * int * int * int = "ocaml_shout_version"

external new_shout : unit -> shout = "ocaml_shout_new"

external get_error : shout -> string = "ocaml_shout_get_error"

(* TODO: return a shout exception? *)
external get_errno : shout -> int = "ocaml_shout_get_errno"

external is_connected : shout -> bool = "ocaml_shout_get_connected"

external set_host : shout -> string -> unit = "ocaml_shout_set_host"

external get_host : shout -> string = "ocaml_shout_get_host"

external set_port : shout -> int -> unit = "ocaml_shout_set_port"

external get_port : shout -> int = "ocaml_shout_get_port"

external set_password : shout -> string -> unit = "ocaml_shout_set_password"

external get_password : shout -> string = "ocaml_shout_get_password"

external set_mount : shout -> string -> unit = "ocaml_shout_set_mount"

external get_mount : shout -> string = "ocaml_shout_get_mount"

external set_name : shout -> string -> unit = "ocaml_shout_set_name"

external get_name : shout -> string = "ocaml_shout_get_name"

external set_url : shout -> string -> unit = "ocaml_shout_set_url"

external get_url : shout -> string = "ocaml_shout_get_url"

external set_genre : shout -> string -> unit = "ocaml_shout_set_genre"

external get_genre : shout -> string = "ocaml_shout_get_genre"

external set_user : shout -> string -> unit = "ocaml_shout_set_user"

external get_user : shout -> string = "ocaml_shout_get_user"

external set_agent : shout -> string -> unit = "ocaml_shout_set_agent"

external get_agent : shout -> string = "ocaml_shout_get_agent"

external set_description : shout -> string -> unit = "ocaml_shout_set_description"

external get_description : shout -> string = "ocaml_shout_get_description"

external set_dumpfile : shout -> string -> unit = "ocaml_shout_set_dumpfile"

external get_dumpfile : shout -> string = "ocaml_shout_get_dumpfile"

(* TODO: abstract type / dedicated functions for parameters? *)
external set_audio_info : shout -> string -> string -> unit = "ocaml_shout_set_audio_info"

external get_audio_info : shout -> string -> string = "ocaml_shout_get_audio_info"

let set_multicast_ip conn = set_audio_info conn "multicast-ip"

let get_multicast_ip conn = get_audio_info conn "multicast-ip"

external set_public : shout -> bool -> unit = "ocaml_shout_set_public"

external get_public : shout -> bool = "ocaml_shout_get_public"

external set_format : shout -> data_format -> unit = "ocaml_shout_set_format"

external get_format : shout -> data_format = "ocaml_shout_get_format"

external set_protocol : shout -> protocol -> unit = "ocaml_shout_set_protocol"

external get_protocol : shout -> protocol = "ocaml_shout_get_protocol"

external open_shout : shout -> unit = "ocaml_shout_open"

external close : shout -> unit = "ocaml_shout_close"

external send : shout -> string -> unit = "ocaml_shout_send"

external send_raw_ : shout -> string -> int = "ocaml_shout_send_raw"

let send_raw shout buf =
  let r = send_raw_ shout buf in
    if r < 0 then raise Send_error
    else r

external sync : shout -> unit = "ocaml_shout_sync"

external delay : shout -> int = "ocaml_shout_delay"

external set_metadata : shout -> (string * string) array -> unit = "ocaml_shout_set_metadata"
