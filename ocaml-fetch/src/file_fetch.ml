(*
 * Copyright 2003-2004  The Savonet Team
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
  * "file" protocol plugin for ocaml-fetch.
  *
  * @author Julien Cristau
  *)

(* $Id$ *)

let hashsize = 10

let used_fd : (int, Unix.file_descr) Hashtbl.t = Hashtbl.create hashsize

let my_flag = function
  | Proto.O_RDONLY -> Unix.O_RDONLY
  | Proto.O_WRONLY -> Unix.O_WRONLY
  | Proto.O_RDWR -> Unix.O_RDWR
  | Proto.O_CREAT -> Unix.O_CREAT
  | Proto.O_TRUNC -> Unix.O_TRUNC

let my_command = function
  | Proto.SEEK_SET -> Unix.SEEK_SET
  | Proto.SEEK_CUR -> Unix.SEEK_CUR
  | Proto.SEEK_END -> Unix.SEEK_END

let openfile =
  begin try
    let fdcount = ref 0 in
      begin fun uri flags mode ->
        assert (String.sub uri 0 7 = "file://");
        let filename = String.sub uri 7 (String.length uri - 7) in
        let file = Unix.openfile filename (List.map my_flag flags) mode in
        let fd = !fdcount in
          incr fdcount;
          Hashtbl.add used_fd fd file;
          fd
      end
  with e -> raise (Fetch.Error e)
  end

let close fd =
  begin try
    Unix.close (Hashtbl.find used_fd fd);
    Hashtbl.remove used_fd fd
  with e -> raise (Fetch.Error e)
  end

let read fd =
  try
    Unix.read (Hashtbl.find used_fd fd)
  with e -> raise (Fetch.Error e)

let lseek fd offset command =
  try
    Unix.lseek (Hashtbl.find used_fd fd) offset (my_command command)
  with e -> raise (Fetch.Error e)

let write fd =
  try
    Unix.write (Hashtbl.find used_fd fd)
  with e -> raise (Fetch.Error e)

let ls uri =
  assert (String.sub uri 0 7 = "file://");
  let l = ref [] in
  let dirname =
    String.sub uri 7 (String.length uri - 7)
    ^ if uri.[String.length uri - 1] = '/' then "" else "/"
  in
    begin try
      let dir = Unix.opendir dirname in
        begin try
          while true do
            let entry = Unix.readdir dir in
            let fullname = dirname ^ entry in
              begin match (Unix.stat fullname).Unix.st_kind with
                | Unix.S_REG ->
                    l := (fullname, Proto.S_REG) :: !l
                | Unix.S_DIR ->
                    l := (fullname, Proto.S_DIR) :: !l
                | Unix.S_CHR
                | Unix.S_BLK
                | Unix.S_LNK
                | Unix.S_FIFO
                | Unix.S_SOCK -> ()
              end
          done; []
        with
          | End_of_file -> Unix.closedir dir; !l
          | e -> Unix.closedir dir; raise e
        end
    with
      | e -> raise (Fetch.Error e)
    end

let is_alive = fun _ -> true

let () =
  Proto.register "file"
    {
      Proto.openfile = openfile;
      Proto.close = close;
      Proto.read = read;
      Proto.lseek = lseek;
      Proto.write = write;
      Proto.ls = ls;
      Proto.is_alive = is_alive;
    }
