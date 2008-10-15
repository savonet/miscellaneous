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

(* $Id$ *)

(* TODO: use a config file for authentification parameters *)

(* server -> share -> wg_hint -> un_hint -> (wg, un, pw) *)
type auth_function = string -> string -> string -> string -> (string * string * string)

type file_descr = int

type dir_handle = int

type open_flag =
  | O_RDONLY
  | O_WRONLY
  | O_RDWR
  | O_CREAT
  | O_EXCL
  | O_TRUNC
  | O_APPEND

type file_perm = int

type file_kind =
  | Workgroup
  | Server
  | File_share
  | Printer_share
  | Comms_share
  | Ipc_share
  | Dir
  | File
  | Link

type dirent = { kind : file_kind ; comment : string ; name : string ; }

type seek_command = (* do not change the order *)
  | SEEK_SET
  | SEEK_CUR
  | SEEK_END

(* Size of the buffer during a copy *)
let buf_size = 64 * 1024

type error =
  | ENOMEM
  | EBUSY
  | EBADF
  | ENOENT
  | EINVAL
  | EEXIST
  | EISDIR
  | EACCES
  | ENODEV
  | ENOTDIR
  | EPERM
  | EXDEV
  | ENOTEMPTY
  | ENOTSUP
  | ENETUNREACH
  | EUNKNOWNERR of int

exception Samba_error of error * string * string

(* Register exceptions in order to be able to raise them from C part of the code. *)
let _ =
  Callback.register_exception "Smbclient.Samba_error" (Samba_error(ENOMEM,"",""))

external c_samba_init : auth_function -> int -> unit  = "ocaml_samba_init"

external openfile : string -> open_flag list -> file_perm -> file_descr  = "ocaml_samba_open"

external c_samba_read : file_descr -> string -> int -> int -> int  = "ocaml_samba_read"

external close : file_descr -> unit = "ocaml_samba_close"

external opendir : string -> dir_handle = "ocaml_samba_opendir"

external closedir: dir_handle -> unit = "ocaml_samba_closedir"

external readdir: dir_handle -> dirent = "ocaml_samba_readdir"

external lseek: file_descr -> int -> seek_command -> int = "ocaml_samba_lseek"

external lseek64: file_descr -> int64 -> seek_command -> int64 = "ocaml_samba_lseek64"

external isavail: string -> bool = "ocaml_samba_isavail"

external error_message: error -> string = "samba_error_message"

(** Initialise samba *)
let init ?(debug=0) fn =
  c_samba_init fn debug

let read fd buf ofs len =
  if ofs < 0 || len < 0 || ofs > String.length buf - len
  then invalid_arg "Unix.read"
  else c_samba_read fd buf ofs len

(* TODO: config file *)
let default_init () = init ~debug:0 (fun _ _ wg un -> wg, un, "")
