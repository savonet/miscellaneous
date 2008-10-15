(*
 * Copyright 2003-2004 Savonet team
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
  * Internal interface of ocaml-fetch.
  *
  * @author Julien Cristau
  *)

(* $Id$ *)

type protocol = string

type file_descr = protocol * int

type file_kind =
  | S_REG
  | S_DIR

type open_flag =
  | O_RDONLY
  | O_WRONLY
  | O_RDWR
  | O_CREAT
  | O_TRUNC

type seek_command =
  | SEEK_SET
  | SEEK_CUR
  | SEEK_END

type file_perm = int

type io =
    {
      openfile : string -> open_flag list -> file_perm -> int;
      close : int -> unit;
      read : int -> string -> int -> int -> int;
      lseek : int -> int -> seek_command -> int;
      write : int -> string -> int -> int -> int;
      ls : string -> (string * file_kind) list;
      is_alive : string -> bool;
    }

module Map = Map.Make(String)
let protos : io Map.t ref = ref Map.empty

let register proto io =
  protos := Map.add proto io !protos
