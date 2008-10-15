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
(**
  Libshout 2 bindings for OCaml.
  
  @author Samuel Mimram
*)

(* $Id$ *)

(** {1 Types and exceptions.} *)

(** A shout connection. *)
type shout

(* Exceptions *)
(** Bad parameters, either nonsense or not applicable due to the current state of the connection. *)
exception Insane

(** A connection with the server could not be established. *)
exception No_connect

(** The server refused to accept a login attemp (bad user name or password?). *)
exception No_login

(** An error occured while sending or receiving data. *)
exception Socket

(** A problem occured while trying to allocate memory (no more memory left?). This exception could be raised by most of the functions. *)
exception Malloc

(** An error occured while updating the metadatas on the server. *)
exception Metadata

(** We are connected to a server. *)
exception Connected

(** We are not connected to a server. *)
exception Unconnected

(** The operation is not supported. *)
exception Unsupported

(** An error occured while sending data. *)
exception Send_error

(** Format of audio data. *)
type data_format =
  | Format_vorbis (** ogg / vorbis *)
  | Format_mp3 (** mp3 *)

(** Kind of protocol to use. *)
type protocol =
  | Protocol_http (** http *)
  | Protocol_xaudiocast (** audiocast *)
  | Protocol_icy (** shoutcast *)




(** {1 Initialization and creation functions.} *)

(** Initialize the shout library. Must be called before anything else. *)
val init : unit -> unit

(** Shut down the shout library, deallocating any global storage. Don't call anything afterwards. This function should be called after having finished to use the shout library. *)
val shutdown : unit -> unit

(** Get a version string as well as the value of the library major, minor, and patch levels, respectively. *)
val version : unit -> string * int * int * int

(** Get a string describing the last shout error to occur.  Only valid until the next call to a [Shout] function. *)
val get_error : shout -> string

(** Get the number of the last error. *)
val get_errno : shout -> int

(** Create a new [shout] value. *)
val new_shout : unit -> shout

(** Am I connected to a shoutcast server? *)
val is_connected : shout -> bool




(** {1 Setting and retrieving preliminary parameters.} *)

(** The following parameters may be set only {i before} calling [open_shout]. They might raise the [Malloc] exception or the [Connected] exception when attempting to change a connection attribute while the connection is open. *)

(** {2 Connection parameters} *)

(** Set the server's hostname or ip address (default: localhost). *)
val set_host : shout -> string -> unit

(** Retrieve the server's hostname or ip address. *)
val get_host : shout -> string

(** Set the server's port (default: 8000). *)
val set_port : shout -> int -> unit

(** Retrieve the server's port. *)
val get_port : shout -> int

(** Set the user to authenticate as (default: source). *)
val set_user : shout -> string -> unit

(** Retrieve the user to authenticate as. *)
val get_user : shout -> string

(** Set the password to authenticate the server with. *)
val set_password : shout -> string -> unit

(** Retrieve the server's password. *)
val get_password : shout -> string

(** Set the protocol to connect to the server with (default: Protocol_http). *)
val set_protocol : shout -> protocol -> unit

(** Retrieve the protocol used to connect to the server. *)
val get_protocol : shout -> protocol

(** Set the stream's audio format (default: Format_vorbis). *)
val set_format : shout -> data_format -> unit

(** Retrieve the stream's audio format. *)
val get_format : shout -> data_format

(** Set the the mountpoint (not supported by the [Protocol_icy] protocol). *)
val set_mount : shout -> string -> unit

(** Retrieve the mountpoint. *)
val get_mount : shout -> string

(** Request that your stream be archived on the server under the specified name. *)
val set_dumpfile : shout -> string -> unit

(** Retrieve the dumpfile name. *)
val get_dumpfile : shout -> string

(** Set the user agent header (default: libshout/VERSION). *)
val set_agent : shout -> string -> unit

(** Retrieve the user agent header. *)
val get_agent : shout -> string



(** {2 Directory parameters (optionnal)} *)

(** Should we ask the server to list the stream in any directories it knows about (default: [false])? *)
val set_public : shout -> bool -> unit

(** Should we ask the server to list the stream in any directories it knows about? *)
val get_public : shout -> bool

(** Set the name of the stream. *)
val set_name : shout -> string -> unit

(** Retrieve the name of the stream. *)
val get_name : shout -> string

(** Set the url of a site about this stream. *)
val set_url : shout -> string -> unit

(** Retrieve the url of a site about this stream. *)
val get_url : shout -> string

(** Set the stream genre. *)
val set_genre : shout -> string -> unit

(** Retrieve the stream genre. *)
val get_genre : shout -> string

(** Set the stream description. *)
val set_description : shout -> string -> unit

(** Retrieve the stream description. *)
val get_description : shout -> string

(** [set_audio_info shout name value] sets the stream audio parameter [name] to the value [value]. *)
val set_audio_info : shout -> string -> string -> unit

(** Retrieve a stream audio parameter. *)
val get_audio_info : shout -> string -> string



(** {2 Multicasting} *)

(** Set the ip for multicasting the stream. *)
val set_multicast_ip : shout -> string -> unit

(** Retrieve the ip for multicasting the stream. *)
val get_multicast_ip : shout -> string




(** {1 Managing the connection and sending data.} *)

(** Open a connection to the server.  All parameters must already be set.
  @raise Insane if host, port or password is unset.
  @raise Connected if the connection has already been opened.
  @raise Unsupported if the protocol / format combination is unsupported (e.g. ogg / vobis may only be sent via the http protocol).
  @raise No_connect if a connection to the server could not be established.
  @raise Socket if an error occured while talking to the server.
  @raise No_login if the server refused login (authentication failed). *)
val open_shout : shout -> unit

(** Close a connection to the server.
  @raise Unconnected if the [shout] value is not currently connected. *)
val close : shout -> unit

(** Send data to the server, parsing it for format specific timing info.
  @raise Unconnected if the [shout] value is not currently connected.
  @raise Socket if an error occured while talking to the server. *)
val send : shout -> string -> unit

(** @deprecated Send unparsed data to the server.  Do not use this unless you know what you are doing.
  @raise Unconnected if the [shout] value is not currently connected.
  @raise Socket if an error occured while talking to the server.
  @return the number of bytes written. *)
val send_raw : shout -> string -> int

(** Put caller to sleep until it is time to send more data to the server. Should be called before every call to [send] (the function [delay] could also be used to determine the amout of time the caller should wait before sendig data). *)
val sync : shout -> unit

(** Amount of time in miliseconds caller should wait before sending again. *)
val delay : shout -> int

(** Set metadata for mp3 streams.
  @raise No_connect if the server refused the connection attempt.
  @raise No_login if the server did not accept your authorization credentials.
  @raise Socket if an error occured talking to the server.
  @raise Unsupported if the format is not mp3.
  @raise Metadata if an other error happened (e.g. bad mount point). *)
val set_metadata : shout -> (string * string) array -> unit
