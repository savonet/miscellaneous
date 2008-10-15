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
  * "ftp" protocol plugin for ocaml-fetch.
  *
  * @author Julien Cristau
  *)

(* $Id$ *)

let hashsize = 10

let used_fd : (int, Ftp.File.file_descr) Hashtbl.t = Hashtbl.create hashsize

let my_flag = function
  | Proto.O_RDONLY -> Ftp.File.O_RDONLY
  | Proto.O_WRONLY -> Ftp.File.O_WRONLY
  | Proto.O_RDWR -> Ftp.File.O_RDWR
  | _ -> raise Fetch.Not_implemented

let my_command = function
  | Proto.SEEK_SET -> Ftp.File.SEEK_SET
  | Proto.SEEK_CUR -> Ftp.File.SEEK_CUR
  | Proto.SEEK_END -> Ftp.File.SEEK_END

let openfile =
  begin try
    let fdcount = ref 0 in
      fun uri flags mode ->
        let file = Ftp.File.openfile uri (List.map my_flag flags) mode in
        let fd = !fdcount in
          incr fdcount;
          Hashtbl.add used_fd fd file;
          fd
  with e -> raise (Fetch.Error e)
  end

let close fd =
  begin try
    Ftp.File.close (Hashtbl.find used_fd fd);
    Hashtbl.remove used_fd fd
  with e -> raise (Fetch.Error e)
  end

let read fd =
  try
    Ftp.File.read (Hashtbl.find used_fd fd)
  with e -> raise (Fetch.Error e)

let lseek fd offset command =
  try
    Ftp.File.lseek (Hashtbl.find used_fd fd) offset (my_command command)
  with e -> raise (Fetch.Error e)

let write fd =
  raise Fetch.Not_implemented

let ls uri =
  begin try
    let slash = if uri.[String.length uri - 1] = '/' then "" else "/" in
      List.map
        (function (a,b) -> match b.Ftp.st_kind with
           | Ftp.S_REG -> (uri ^ slash ^ a),Proto.S_REG
           | Ftp.S_DIR -> (uri ^ slash ^ a),Proto.S_DIR
           | _ -> assert false)
        (List.filter
           (fun (a,b) -> b.Ftp.st_kind =
              Ftp.S_REG || b.Ftp.st_kind = Ftp.S_DIR)
           (Ftp.File.ls uri)
        )
  with e -> raise (Fetch.Error e)
  end

let is_alive = fun _ -> false

let () =
  Proto.register "ftp"
    {
      Proto.openfile = openfile;
      Proto.close = close;
      Proto.read = read;
      Proto.lseek = lseek;
      Proto.write = write;
      Proto.ls = ls;
      Proto.is_alive = is_alive;
    }
