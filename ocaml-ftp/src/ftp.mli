(* 
   Copyright 2003 Savonet team

   This file is part of Ocaml-ftp.
   
   Ocaml-ftp is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   Ocaml-ftp is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with Ocaml-ftp; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*)

(**
  Functions for accessing files via ftp.

  @author Samuel Mimram
*)

(* $Id$ *)

(** An ftp connection to an ftp server. *)
type ftp_connection

(** Kind of a file. *)
type file_kind =
    | S_REG (** regular file *)
    | S_DIR (** directory *)
    | S_CHR (** character device *)
    | S_BLK (** block device *)
    | S_LNK (** symbolic link *)
    | S_FIFO (** named pipe *)
    | S_SOCK (** socket *)

(** Permissions of a file. *)
type file_perm = int

(** Properties of a file. *)
type stats =
    {
      st_kind : file_kind; (** kind of the file *)
      st_perm : file_perm; (** access rights *)
      st_nlink : int; (** number of links *)
      st_un : string; (** user name of the owner *)
      st_gn : string; (** group of the file's group *)
      st_size : int; (** size in bytes *)
      st_mtime : float; (** last modification time *)
    }

(** The library could not [stat] correctly (the rfc of the ftp is infamous and does not specify the format of the output of the command LIST). *)
exception Unrecognised_format

(** [connect server port login pass] connects to the server named [server] on port [port] using the given login and password. *)
val connect : string -> int -> string -> string -> ftp_connection

(** Close a previously opened connection. *)
val disconnect : ftp_connection -> unit

(** Shoud the data connection be done in passive mode? (not used for now: the connection is always in passive mode). *)
val set_passive : ftp_connection -> bool -> unit

(** Get the directory we're currently in on the server. *)
val get_cur_dir : ftp_connection -> string

(** Change the current directory. *)
val chdir : ftp_connection -> string -> unit

(** Change the current directory to the surrounding one. *)
val chdir_up : ftp_connection -> unit

(** List all the files contained in a directory. *)
val list_files : ftp_connection -> string -> string list

(** Get the size of a file (in bytes). *)
val get_file_size : ftp_connection -> string -> int

(** List all the files contained in a directory, specifying its properties. WARNING: it does not always work yet (in fact it has only been tested with proftpd). *)
val ls : ftp_connection -> string -> (string * stats) list

(** Get the properties of a file. If you only want its size, you should use [get_size] which is supposed to work better. *)
val stat : ftp_connection -> string -> stats

(** [get_file fc src dst] downloads the file [src] and stores it in [dst]. Warning: if the file already exists it is replaced. *)
val get_file : ftp_connection -> string -> string -> unit

(** [resume_file fc src dst ofs] downloads the file [src] starting at offset [ofs] and appends it to [dst]. Raises [Not_found] if the file does not already exists. *)
val resume_file : ftp_connection -> string -> string -> int -> unit

(** [get_file_portion fc src file_ofs buf ofs len] downloads [len] octets of file [src] starting at position [file_ofs] and stores it in [buf] starting at position [ofs]. Returns the number of bytes actually read. *)
val get_file_portion : ftp_connection -> string -> int -> string -> int -> int -> int

(** [mv fc src dst] moves the file [src] to [dst]. *)
val mv : ftp_connection -> string -> string -> unit

(** Remove a file. *)
val rm : ftp_connection -> string -> unit

(** Remove a directory. *)
val rmdir : ftp_connection -> string -> unit

(** Create a directory. *)
val mkdir : ftp_connection -> string -> unit

(** Don't do anything :) *)
val nop : ftp_connection -> unit

(** Type of the module providing high-level functions to access files via ftp. *)
module type FILE =
sig
  (** List files and their properties of a directory. *)
  val ls : string -> (string * stats) list

  (** Type of file descriptors. *)
  type file_descr
  
  (** Open files: what for? *)
  type open_flag =
    | O_RDONLY
    | O_WRONLY
    | O_RDWR

  (** [openfile name flags perms] opens the file named [name] with flags [flags] and mode [mode] (in octal). *)
  val openfile : string -> open_flag list -> file_perm -> file_descr

  (** Close a previously opened file. *)
  val close : file_descr -> unit

  (** Read data in an opened file. *)
  val read : file_descr -> string -> int -> int -> int

  (** Positioning modes for [lseek]. *)
  type seek_command =
    | SEEK_SET (** indicates positions relative to the beginning of the file *)
    | SEEK_CUR (** indicates positions relative to the current position *)
    | SEEK_END (** indicates positions relative to the end of the file *)

  (** Seek in an opened file. *)
  val lseek : file_descr -> int -> seek_command -> int
end

(** High-level functions to access files via ftp. *)
module File : FILE
