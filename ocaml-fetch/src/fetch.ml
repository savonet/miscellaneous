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
  * Module fetch: universal fetcher.
  * It currently handles samba, ftp and local files.
  *
  * @author Gaétan Richard, Samuel Mimram, Julien Cristau
  *)

(* $Id$ *)

type protocol = string

exception Unknown_protocol of protocol
exception Bad_URI
exception Error of exn
exception Not_implemented

type uri = string

type seek_command =
  | SEEK_SET
  | SEEK_CUR
  | SEEK_END

type file_perm = int

type open_flag =
  | O_RDONLY
  | O_WRONLY
  | O_RDWR
  | O_CREAT
  | O_TRUNC

type file_descr = Proto.file_descr

type file_kind = S_REG | S_DIR

let translate_command = function
  | SEEK_SET -> Proto.SEEK_SET
  | SEEK_CUR -> Proto.SEEK_CUR
  | SEEK_END -> Proto.SEEK_END

let translate_flags = function
  | O_RDONLY -> Proto.O_RDONLY
  | O_WRONLY -> Proto.O_WRONLY
  | O_RDWR -> Proto.O_RDWR
  | O_CREAT -> Proto.O_CREAT
  | O_TRUNC -> Proto.O_TRUNC

let translate_kind = function
  | Proto.S_REG -> S_REG
  | Proto.S_DIR -> S_DIR

let get_protocol uri =
  let r = Str.regexp "^\\([^:]*\\)://" in
  if Str.string_match r uri 0 then
    Str.matched_group 1 uri
  else raise Bad_URI

let protos = Proto.protos
module Map = Proto.Map

let find_proto p =
  try
    Map.find p !protos
  with Not_found ->
    raise (Unknown_protocol p)

let openfile uri flags mode =
  let proto = get_protocol uri in
      proto,
      ((find_proto proto).Proto.openfile
         uri (List.map translate_flags flags) mode)

let close (proto,fd) =
    (find_proto proto).Proto.close fd

let read (proto,fd) =
    (find_proto proto).Proto.read fd

let write (proto,fd) =
    (find_proto proto).Proto.write fd

let lseek (proto,fd) offset whence =
    (find_proto proto).Proto.lseek fd offset (translate_command whence)

let ls uri =
  let proto = get_protocol uri in
    List.map (fun (a,b) -> (a,translate_kind b))
      ((find_proto proto).Proto.ls uri)

let cp src dst =
  let buflen = 64 * 1024 in
  let buf = String.create buflen in
  let fi = openfile src [O_RDONLY] 0o644 in begin try
    let fo = openfile dst [O_WRONLY; O_CREAT; O_TRUNC] 0o644 in begin try
      let flen = lseek fi 0 SEEK_END in
      let written = ref 0 in
        ignore (lseek fi 0 SEEK_SET);
        while !written < flen
        do
          let l = read fi buf 0 buflen in
            ignore (write fo buf 0 l);
            written := !written + l
        done
      with e -> close fo; raise e
      end;
      close fo
  with e -> close fi; raise e
  end;
  close fi

let is_alive uri =
  let proto = get_protocol uri in
    (find_proto proto).Proto.is_alive uri

let supported_protocols () =
  Map.fold (fun p _ l -> p::l) !protos []

let basename uri =
  let r = Str.regexp "/\\([^/]*$\\)" in
    if Str.string_match r uri 0
    then Str.matched_group 1 uri
    else ""
