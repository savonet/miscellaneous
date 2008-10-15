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
  * "http" protocol plugin for ocaml-fetch.
  *
  * @author Samuel Mimram
  *)

(* $Id$ *)

(* TODO: very basic implementation, does not really support seeks, etc. *)

type file =
    {
      f_server : string;
      f_path : string;
      mutable f_pos : int;
      f_ic : in_channel;
      f_oc : out_channel;
      mutable f_len : int;
    }

let hashsize = 10

let used_fd : (int, file) Hashtbl.t = Hashtbl.create hashsize

let get_fd = Hashtbl.find used_fd

let openfile =
  try
    let fdcount = ref 0 in
      fun uri flags mode ->
        let re_uri = Str.regexp "http://\\([^/]+\\)\\(.*\\)" in
          if Str.string_match re_uri uri 0 then
            (
              let fd = !fdcount in
              let server = Str.matched_group 1 uri in
              let path = Str.matched_group 2 uri in
              let h =
                try
                  Unix.gethostbyname server
                with
                  | Not_found -> failwith "Host not found"
              in
              let ic, oc = Unix.open_connection (Unix.ADDR_INET((h.Unix.h_addr_list).(0), 80)) in
              let file =
                {
                  f_server = server;
                  f_path = path;
                  f_pos = 0;
                  f_ic = ic;
                  f_oc = oc;
                  f_len = -1;
                }
              in
              let buf = ref "bla" in
                output_string oc ("GET " ^ path ^ " HTTP/1.1\n");
                output_string oc ("Host: " ^ server ^ "\n");
                output_string oc "\n";
                flush oc;
                while !buf <> ""
                do
                  buf := input_line ic;
                  let len = String.length !buf in
                    if !buf.[len - 1] = '\r' then
                      buf := String.sub !buf 0 (len - 1);
                    (
                      try
                        Scanf.sscanf !buf "Content-Length: %d" (fun l -> file.f_len <- l);
                      with
                        | _ -> ()
                    );
                done;
                incr fdcount;
                Hashtbl.add used_fd fd file;
                fd
            )
          else
            raise Fetch.Bad_URI
  with
    | e -> raise (Fetch.Error e)

let read fd buf ofs len =
  input (get_fd fd).f_ic buf ofs len

let close fd =
  Unix.shutdown_connection (get_fd fd).f_ic;
  Hashtbl.remove used_fd fd

let lseek fd offs flag =
  let new_pos =
    match flag with
      | Proto.SEEK_SET -> offs
      | Proto.SEEK_CUR -> (get_fd fd).f_pos + offs
      | Proto.SEEK_END -> (get_fd fd).f_len
  in
    (get_fd fd).f_pos <- new_pos; new_pos

let write _ _ _ _ =
  raise Fetch.Not_implemented

let ls _ =
  raise Fetch.Not_implemented

let is_alive _ =
  raise Fetch.Not_implemented

let () =
  Proto.register "http"
    {
      Proto.openfile = openfile;
      Proto.close = close;
      Proto.read = read;
      Proto.lseek = lseek;
      Proto.write = write;
      Proto.ls = ls;
      Proto.is_alive = is_alive;
    }
