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
  * "smb" protocol plugin for ocaml-fetch.
  *
  * @author Julien Cristau
  *)

(* $Id$ *)

let hashsize = 10

let used_fd : (int, Smbclient.file_descr) Hashtbl.t = Hashtbl.create hashsize

let my_flag = function
  | Proto.O_RDONLY -> Smbclient.O_RDONLY
  | Proto.O_WRONLY -> Smbclient.O_WRONLY
  | _ -> raise Fetch.Not_implemented

let my_command = function
  | Proto.SEEK_SET -> Smbclient.SEEK_SET
  | Proto.SEEK_CUR -> Smbclient.SEEK_CUR
  | Proto.SEEK_END -> Smbclient.SEEK_END

let openfile =
  let fdcount = ref 0 in
    fun uri flags mode ->
      begin try
        let file = Smbclient.openfile uri (List.map my_flag flags) mode in
        let fd = !fdcount in
          incr fdcount;
          Hashtbl.add used_fd fd file;
          fd
      with Smbclient.Samba_error _ as e -> raise (Fetch.Error e)
      end

let close fd =
  begin try
    Smbclient.close (Hashtbl.find used_fd fd);
    Hashtbl.remove used_fd fd
  with e -> raise (Fetch.Error e)
  end

let read fd =
  try
    Smbclient.read (Hashtbl.find used_fd fd)
  with e -> raise (Fetch.Error e)

let lseek fd offset command =
  try
    Smbclient.lseek (Hashtbl.find used_fd fd) offset (my_command command)
  with e -> raise (Fetch.Error e)

let write fd =
  raise Fetch.Not_implemented

let ls uri =
  begin try
    let l = ref [] in
    let dir = Smbclient.opendir uri in
      begin try
        while true do
          let entry = Smbclient.readdir dir in
            match entry.Smbclient.kind with
              | Smbclient.Server ->
                  l := ("smb://" ^ entry.Smbclient.name, Proto.S_DIR) :: !l
              | Smbclient.File_share
              | Smbclient.Dir ->
                  l := (uri ^ "/" ^ entry.Smbclient.name, Proto.S_DIR) :: !l
              | Smbclient.File ->
                  l := (uri ^ "/" ^ entry.Smbclient.name, Proto.S_REG) :: !l
              | Smbclient.Link
              | Smbclient.Ipc_share
              | Smbclient.Comms_share
              | Smbclient.Printer_share ->
                  ()
              | Smbclient.Workgroup -> assert false
        done; []
      with
        | End_of_file -> Smbclient.closedir dir; !l
        | e -> Smbclient.closedir dir; raise e
      end
  with
    | e -> raise (Fetch.Error e)
  end

let is_alive = fun _ -> false

let () =
  Smbclient.default_init();
  Proto.register "smb"
    {
      Proto.openfile = openfile;
      Proto.close = close;
      Proto.read = read;
      Proto.lseek = lseek;
      Proto.write = write;
      Proto.ls = ls;
      Proto.is_alive = is_alive;
    }
