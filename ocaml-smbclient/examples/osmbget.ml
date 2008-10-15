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
  Smbget. Like wget ... but for samba !

  @author Samuel Mimram
*)

(* $Id$ *)

open Unix

let src = ref ""
let dst = ref ""
let workgroup = ref "WORKGROUP"
let user = ref "guest"
let pass = ref "guest"

let bufsize = 64 * 1024

let expanse_path path =
  if path.[0] = '~' then
    ((Unix.getenv "HOME") ^ (String.sub path 1 ((String.length path) - 1)))
  else
    path

let _ =
  Arg.parse
    [
      "-p", Arg.String (fun s -> pass := s), "\tspecify the password";
      "-u", Arg.String (fun s -> user := s), "\tspecify the username";
      "-w", Arg.String (fun s -> workgroup := s), "\tspecify the workgroup"
    ]
    (
      let pnum = ref (-1) in
	(fun s -> incr pnum; match !pnum with
	   | 0 -> src := s
	   | 1 -> dst := s
	   | _ -> Printf.eprintf "Error: too many arguments\n"; exit 1
	)
    ) "usage: osmbget [options] source destination";
  if !src = "" || !dst = "" then
    (
      Printf.eprintf "Error: please give source and destination\n";
      exit 1
    );
  while String.length !src > 0 && !src.[0] = ' '
  do
    src := String.sub !src 1 ((String.length !src) - 1)
  done;
  if String.length !src > 2 && String.sub !src 0 2 = "//" then
    src := "smb:" ^ !src
  else if String.length !src > 7 && String.sub !src 0 7 = "file://" then (* for windows *)
    src := "smb:" ^ (String.sub !src 5 ((String.length !src ) - 5));
  if not ((String.sub !src 0 6) = "smb://") then
    (
      Printf.eprintf "Error: invalid source file\n";
      exit 1
    );
  (
    try
      if (Unix.stat !dst).Unix.st_kind = Unix.S_DIR then
	dst := !dst
	^ (if !dst.[(String.length !dst) - 1] != '/' then "/" else "")
	^ Filename.basename !src
    with
      | Unix.Unix_error (_, "stat", _) -> ()
  );
  src := expanse_path !src;
  dst := expanse_path !dst;
  Printf.printf "Getting file %s...\n\n" !src;
  Smbclient.default_init ();
  try
    let buf = String.create bufsize in
    let inf = Smbclient.openfile !src [Smbclient.O_RDONLY] 644 in
    let outf = openfile !dst [O_WRONLY; O_CREAT; O_TRUNC] 644 in
    let flen = Smbclient.lseek inf 0 Smbclient.SEEK_END in
    let read = ref 0 in
      ignore (Smbclient.lseek inf 0 Smbclient.SEEK_SET);
      while !read < flen
      do
	let r = Smbclient.read inf buf 0 bufsize in
	  ignore (write outf buf 0 r);
	  read := !read + r;
	  Printf.printf "\rGot %d bytes on %d bytes (%f%%)" !read flen ((float_of_int !read) /. (float_of_int flen) *. 100.);
      done;
      Smbclient.close inf;
      close outf;
      Printf.printf "\n\nGot file !\n"
  with
    | e -> (* Printf.eprintf "Error while getting file\n"; exit 2 *) raise e

