(* 
   Copyright 2003 Savonet team

   This file is part of Ocaml-smbclient.
   
   Ocaml-smbclient is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   Ocaml-smbclient is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with Ocaml-smbclient; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*)
(**
  OCaml bindings for the smbclient library.

  @author Gaétan Richard, Samuel Mimram
*)

(* $Id$ *)

(** Type of an authentification function for samba. The function takes (server, share, wg_hint, un_hint) as argument and should return (workgroup, user, password). *)
type auth_function = string -> string -> string -> string -> (string * string * string)

(** Abstract type of file descriptors. *)
type file_descr

(** Abstract type of directories handles. *)
type dir_handle

(** Flags for specifying how to open a file. *)
type open_flag =
  | O_RDONLY (** read only *)
  | O_WRONLY (** write only *)
  | O_RDWR (** read and write *)
  | O_CREAT (** If the file does not exist it will be created. *)
  | O_EXCL (** When used with O_CREAT, if the file already exists it is an error and the open will fail. *)
  | O_TRUNC (** If the file already exists it will be truncated. *)
  | O_APPEND (** The file is opened in append mode *)


(** Permissions of a file. *)
type file_perm = int

(** Kind of a file. *)
type file_kind =
  | Workgroup (** a workgroup *)
  | Server (** a server *)
  | File_share (** a file share *)
  | Printer_share (** a printer *)
  | Comms_share
  | Ipc_share
  | Dir (** a directory *)
  | File (** a file *)
  | Link (** a symbolic link *)

(** A filename and its kind. *)
type dirent = { kind : file_kind ; comment : string ; name : string ; }

(** Way seek commands should be interpreted. *)
type seek_command =
  | SEEK_SET
  | SEEK_CUR
  | SEEK_END

type error =
  | ENOMEM (** Not enough memory *)
  | EBUSY (** Resource unavailable *)
  | EBADF (** Bad file descriptor *)
  | ENOENT (** No such file or directory *)
  | EINVAL (** Invalid argument *)
  | EEXIST (** File exists *)
  | EISDIR (** Is a directory *)
  | EACCES (** Permission denied *)
  | ENODEV (** No such device *)
  | ENOTDIR (** Not a directory *)
  | EPERM (** Operation not permitted *)
  | EXDEV (** Invalid link *)
  | ENOTEMPTY (** Directory not empty *)
  | ENOTSUP (** Operation not supported *)
  | ENETUNREACH (** Network is unreachable *)
  | EUNKNOWNERR of int  (** Unknown error *)

exception Samba_error of error * string * string
(** Raised by the library calls below when an error is encountered.
   The first component is the error code; the second component
   is the function name; the third component is the string parameter
   to the function, if it has one, or the empty string otherwise. *)

val error_message : error -> string

(** Initialize the samba library.
  @param debug print debug message (0 to 5)
  @param auth_function the function used for obtain share rigth
*)
val init : ?debug:int -> auth_function -> unit

(** Same as above with reasonable default parameters *)
val default_init : unit -> unit

(* (** Is a file available ? *)
val is_avail : string -> bool *)
(* val get_type : string -> file_kind *)

(** [openfile filename flags mode] opens the file [filename]. [filename] should be of the form "smb://TOTO/path/tatu.mp3".
  [flags] must contain exactly one of [O_RDONLY], [O_WRONLY], [O_RDWR]. *)
val openfile : string -> open_flag list -> file_perm -> file_descr

(** [read fd buf ofs len] reads [len] bytes in the file [fd] storing them in [buf], starting at position [ofs]. *)
val read : file_descr -> string -> int -> int -> int

(** Seel in a file. *)
val lseek : file_descr -> int -> seek_command -> int

(** Close a previously opened file. *)
val close : file_descr -> unit

(** Open a directory. *)
val opendir : string -> dir_handle

(** Close a previously opened directory. *)
val closedir : dir_handle -> unit

(** Get the next entry in the directory or [End_of_file] if none is left. *)
val readdir : dir_handle -> dirent
