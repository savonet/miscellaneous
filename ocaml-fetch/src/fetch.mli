(*
 *  Copyright 2003-2004  The Savonet Team
 *
 * This file is part of Ocaml-fetch.
 *
 * Ocaml-fetch is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Ocaml-fetch is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Ocaml-fetch; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *)

(**
  * Module fetch: universal fetcher. It currently handles samba,
  * ftp and local files.
  *
  * @author Gaétan Richard, Samuel Mimram, Julien Cristau
  *)

(* $Id$ *)


(** Protocol (may be "file", "ftp", "smb", etc. cf [supported_protocols]). *)
type protocol = string

(** The protocol-specific backend raised an exception. *)
exception Error of exn

(** Operation not implemented. *)
exception Not_implemented

(** Tried to use an unknown protocol. *)
exception Unknown_protocol of protocol

(** URI provided was not syntaxicaly correct. *)
exception Bad_URI

(** An URI (Uniform Resource Identifier). For example "ftp://server/file". *)
type uri = string

(** Get the list of supported protocols. *)
val supported_protocols : unit -> protocol list

(** Get the protocol specified by an URI. *)
val get_protocol : uri -> protocol

(** Flags for opening files. *)
type open_flag =
  | O_RDONLY (** read only *)
  | O_WRONLY (** write only *)
  | O_RDWR (** read and write *)
  | O_CREAT (** create the file if it does not exist *)
  | O_TRUNC (** truncate the file if it does exist *)

(** Flags for seeking in files. *)
type seek_command =
  | SEEK_SET
  | SEEK_CUR
  | SEEK_END

(** The type of file access rights. *)
type file_perm = int

(** The abstract type of file descriptors. *)
type file_descr

(** File kind. *)
type file_kind =
  | S_REG (** regular file *)
  | S_DIR (** directory *)

(** Open the named file with the given flags. Third argument is the permissions
  * to give to the file if it is created. Return a file descriptor on the named
  * file.
  *)
val openfile : uri -> open_flag list -> file_perm -> file_descr

(** Close a file descriptor. *)
val close : file_descr -> unit

(** [read fd buff ofs len] reads [len] characters from descriptor [fd], storing
  * them in string [buff], starting at position [ofs]  in string [buff].
  *
  * @return the number of characters actually read.
  *)
val read : file_descr -> string -> int -> int -> int

(** [write fd buff ofs len] writes... TODO *)
val write : file_descr -> string -> int -> int -> int

(** Set the current position for a file descriptor. *)
val lseek : file_descr -> int -> seek_command -> int

(** List contents of a directory. *)
val ls : uri -> (uri * file_kind) list

(** Get the filename only in a full uri. For example
  * [basename "smb://babasse/tatu.mp3"] returns "tatu.mp3".
  *)
val basename : string -> string

(** [cp source dest] copies the file [source] to [dest] (both arguments are
  * uri).
  *)
val cp : uri -> uri -> unit

(** Is a server alive and available? *)
val is_alive : uri -> bool
