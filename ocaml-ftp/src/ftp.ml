(* 
   Copyright 2003 Savonet team

   This file is part of Ocaml-ftp.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*)

(* $Id$ *)

open Unix

exception Unrecognised_format
exception Host_not_found
exception Not_connected
exception Already_connected
exception Ftp_error of int * string

type file_kind =
    | S_REG
    | S_DIR
    | S_CHR
    | S_BLK
    | S_LNK
    | S_FIFO
    | S_SOCK

type file_perm = int

type stats =
    {
      st_kind : file_kind;
      st_perm : file_perm;
      st_nlink : int;
      st_un : string;
      st_gn : string;
      st_size : int;
      st_mtime : float;
    }

type ftp_connection =
    {
      control : in_channel * out_channel;
      host : host_entry;
      mutable data_port : int;
      mutable passive : bool;
    }

type representation_type = T_ascii | T_ebcdic | T_image | T_non_print | T_telnet_format_effectors | T_cariage_control | T_byte_size of int

let string_of_representation_type = function
  | T_ascii -> "A"
  | T_ebcdic -> "E"
  | T_image -> "I"
  | T_non_print -> "N"
  | T_telnet_format_effectors -> "T"
  | T_cariage_control -> "C"
  | T_byte_size n -> "L " ^ (string_of_int n)

type file_structure = S_file | S_record | S_page

let string_of_file_structure = function
  | S_file -> "F"
  | S_record -> "R"
  | S_page -> "P"

type transfer_mode = M_stream | M_block | M_compressed

let string_of_transfer_mode = function
  | M_stream -> "S"
  | M_block -> "B"
  | M_compressed -> "C"

type command =
  | Username of string (** USER *)
  | Password of string (** PASS *)
  | Account of string (** ACCT *)
  | Change_working_directory of string (** CWD *)
  | Change_directory_up (** CDUP *)
  | Structure_mount of string (** SMNT *)
  | Logout (** QUIT *)
  | Reinitialize (** REIN *)
  | Data_port of string (** PORT *)
  | Passive (** PASV *)
  | Representation_type of representation_type (** TYPE *)
  | File_structure of file_structure (** STRU *)
  | Transfer_mode of transfer_mode (** MODE *)
  | Retrieve of string (** RETR *)
  | Store of string (** STOR *)
  | Store_unique (** STRU *)
  | Append of string (** APPE *)
  | Allocate of int (** ALLO *)
  | Restart of int (** REST *)
  | Rename_from of string (** RNFR *)
  | Rename_to of string (** RNTO *)
  | Abort (** ABOR *)
  | Delete of string (** DELE *)
  | Remove_directory of string (** RMD *)
  | Make_directory of string (** MKD *)
  | Print_working_directory (** PWD *)
  | List of string (** LIST *)
  | Name_list of string (** NLST *)
  | Site_parameters of string (** SITE *)
  | System (** SYST *)
  | Status of string (** STAT *)
  | Help (** HELP *)
  | Noop (** NOOP *)

let string_of_command = function
  | Username u -> "USER " ^ u
  | Password p -> "PASS " ^ p
  | Account a -> "ACCT " ^ a
  | Change_working_directory d -> "CWD " ^ d
  | Change_directory_up -> "CDUP"
  | Structure_mount s -> "SMNT " ^ s
  | Reinitialize -> "REIN"
  | Logout -> "QUIT"
  | Data_port _ -> failwith "DATA: not yet implemented!" (* TODO *)
  | Passive -> "PASV"
  | Representation_type t -> "TYPE " ^ (string_of_representation_type t)
  | File_structure s -> "STRU " ^ (string_of_file_structure s)
  | Transfer_mode m -> "MODE " ^ (string_of_transfer_mode m)
  | Retrieve f -> "RETR " ^ f
  | Store f -> "STORE " ^ f
  | Store_unique -> "STOU"
  | Append f -> "APPE " ^ f
  | Allocate n -> "ALLO " ^ (string_of_int n)
  | Restart n -> "REST " ^ (string_of_int n)
  | Rename_from f -> "RNFR " ^ f
  | Rename_to f -> "RNTO " ^ f
  | Abort -> "ABOR"
  | Delete f -> "DELE " ^ f
  | Remove_directory d -> "RMD " ^ d
  | Make_directory d -> "MKD " ^ d
  | Print_working_directory -> "PWD"
  | List d -> "LIST " ^ d
  | Name_list d -> "NLST " ^ d
  | Site_parameters p -> "SITE " ^ p
  | System -> "SYST"
  | Status f -> "STAT " ^ f
  | Help -> "HELP"
  | Noop -> "NOOP"

let no_trailing_cr s =
  let l = (String.length s) - 1 in
    if s.[l] = '\r' then String.sub s 0 l else s

let read_answer fc =
  let ic, _ = fc.control in
  let is_digit = function
    | '0'..'9' -> true
    | _ -> false
  in
  let more_to_come answer =
    not (is_digit answer.[0] && is_digit answer.[1] && is_digit answer.[2] && answer.[3] = ' ')
  in
  let get_text answer =
    String.sub answer 4 ((String.length answer) - 4)
  in
  let answered = ref "" in
  let answer = ref (input_line ic) in
    while more_to_come !answer
    do
      answered := !answered ^ (get_text !answer) ^ "\n";
      answer := input_line ic
    done;
    answered := !answered ^ (get_text !answer);
    (int_of_string (String.sub !answer 0 3)), (no_trailing_cr !answered)

let check (n, s) =
  flush_all (); (* TODO: why? *)
  if n >= 400 then raise (Ftp_error (n, s))

let cread_answer fc = check (read_answer fc)

let send_command fc cmd =
  let _, oc = fc.control in
    output_string oc ((string_of_command cmd) ^ "\n");
    flush oc;
    (* Printf.printf "<- %s\n" (string_of_command cmd); *)
    read_answer fc

let csend_command fc cmd = check (send_command fc cmd)

let get_pasv_port (n, s) =
  if n <> 227 then
    (
      (* Printf.eprintf "Pasv error: %s\n" s; *)
      failwith (Printf.sprintf "pasv (%d): %s" n s)
       (* raise Not_found;*)
    );
  let re = Str.regexp "Entering Passive Mode ([0-9]+,[0-9]+,[0-9]+,[0-9]+,\\([0-9]+\\),\\([0-9]+\\))" in
    if not (Str.string_match re s 0) then raise Not_found;
    let p1 = int_of_string (Str.matched_group 1 s)
    and p2 = int_of_string (Str.matched_group 2 s)
    in
      p1 * 256 + p2

let connect host port user pass =
  let h =
    try
      gethostbyname host
    with
      | Not_found -> raise Host_not_found
  in
  let fc =
    {
      host = h;
      control = open_connection (ADDR_INET((h.h_addr_list).(0), port));
      data_port = 2048; (* TODO: could be a random port between 2048 and 65535 *)
      passive = false;
    }
  in
    cread_answer fc;
    csend_command fc (Username user);
    csend_command fc (Password pass);
    csend_command fc (Representation_type T_image);
    fc

(* TODO: handle errors when we weren't connected *)
let disconnect fc =
  let ic, _ = fc.control in
    check (send_command fc Logout);
    shutdown_connection ic

let set_passive fc p =
  fc.passive <- p

let connect_data fc =
  (* TODO: check and use passive *)
  let r = send_command fc Passive in
  let n, s = r in
    check r;
    let data_port = get_pasv_port r in
    let icd, ocd = open_connection (ADDR_INET((fc.host.h_addr_list).(0), data_port)) in
      output_char ocd 'x'; (* warum denn ?? *)
      flush ocd;
      (* Printf.printf "=> data connection opened on port %d...\n" data_port; *)
      icd, ocd

let get_cur_dir fc =
  let r = send_command fc Print_working_directory in
  let n, s = r in
  let re = Str.regexp "\"\\([^\"]*\\)\"" in
    if n <> 257 then raise Not_found;
    check r;
    if not (Str.string_partial_match re s 0) then raise Not_found;
    Str.matched_group 1 s

let chdir fc dir =
  let r = send_command fc (Change_working_directory dir) in
  let n, _ = r in
    if n = 550 then raise Not_found;
    check r

let chdir_up fc =
  let r = send_command fc Change_directory_up in
    check r

(* append param: should we append data ? *)
let get_file_a append fc fin fout =
  let icd, _ = connect_data fc in
  let flags = if append then [O_WRONLY; O_APPEND] else [O_WRONLY; O_TRUNC; O_CREAT] in
  let foutd = openfile fout flags 0o644 in
  let buf_len = 16384 in
  let buf = String.create buf_len in
  let len = ref 1 in
  let r = send_command fc (Retrieve fin) in
    if (fst r) = 550 then raise Not_found;
    check r;
    (	
      try
	while !len <> 0
	do
	  len := input icd buf 0 buf_len;
	  (* TODO: raise a proper error *)
	  if write foutd buf 0 !len <> !len then failwith "Could not write enough bytes !!??";
	done;
      with
	| Sys_error e when e = "Connection reset by peer" -> ()
    );
    close foutd

let get_file = get_file_a false

let resume_file fc fin fout ofs =
  csend_command fc (Restart ofs);
  get_file_a true fc fin fout

let start_reading fc fin ofs =
  let icd, _ = connect_data fc in
    if ofs <> 0 then csend_command fc (Restart ofs);
    let r = send_command fc (Retrieve fin) in
      if (fst r) = 550 then raise Not_found;
      check r; icd

let stop_reading fc icd =
  (* TODO: shutdown_connection? *)
  close_in icd;
  let r = read_answer fc in
  let n = fst r in
    if n <> 450 && n <> 451 then check r

let get_file_portion fc fin ofs buf buf_ofs len =
  let icd = start_reading fc fin ofs in
  let len = input icd buf buf_ofs len in
    (*
    close_in icd; (* why doesn't shutdown_connection icd; work ? *)
    let r = read_answer fc in
    let n = fst r in
      if n <> 450 && n <> 451 then check r;
    *)
    stop_reading fc icd;
    len

let list_files fc dir =
  let icd, ocd = connect_data fc in
  let r = send_command fc (Name_list dir) in
  let n = fst r in
    if n = 550 then raise Not_found;
    check r;
    let ret = ref [] in
    let len = ref 1 in
      (
	try
	  while true
	  do
	    ret := no_trailing_cr (input_line icd) :: !ret;
	  done;
	with
	  | End_of_file -> ()
	  | Sys_error e when e = "Connection reset by peer" -> ()
      );
      cread_answer fc;
      (* TODO: is it necessary to rev? *)
      List.rev !ret

let list fc path =
  let icd, ocd = connect_data fc in
  let r = send_command fc (List path) in
  let n = fst r in
    if n = 550 then raise Not_found;
    check r;
    let ret = ref [] in
      (
	try
	  while true
	  do
	    let ln = no_trailing_cr (input_line icd) in
	      ret := ln :: !ret
	  done;
	with
	  | End_of_file -> ()
	  | Sys_error e when e = "Connection reset by peer" -> ()
      );
      cread_answer fc;
      List.rev !ret

let ls fc path =
  let re = Str.regexp "^\\([bcdlps\\-]\\)\\([rwxstST\\-]+\\)[ ]+\\([0-9]+\\)[ ]+\\([^ ]+\\)[ ]+\\([^ ]+\\)[ ]+\\([0-9]+\\)[ ]+\\([a-zA-Z]+\\)[ ]+\\([0-9]+\\)[ ]+\\(\\(\\([0-9]+\\):\\([0-9]+\\)\\)\\|\\([0-9]+\\)\\)[ ]+\\(.+\\)$" in
    List.map
      (fun ln ->
	 if Str.string_match re ln 0 then
	   (
	     (* Printf.printf "matched: %s\n" ln; *)
	     let kind =
	       match Str.matched_group 1 ln with
		 | "-" -> S_REG
		 | "d" -> S_DIR
		 | "c" -> S_CHR
		 | "b" -> S_BLK
		 | "l" -> S_LNK
		 | "p" -> S_FIFO (* ??? *)
		 | "s" -> S_SOCK
		 | _ -> raise (Sys_error "ls") (* TODO *)
	     in
	     let nlink = int_of_string (Str.matched_group 3 ln) in
	     let un = Str.matched_group 4 ln in
	     let gn = Str.matched_group 5 ln in
	     let size = int_of_string (Str.matched_group 6 ln) in
	     let fname = Str.matched_group 14 ln in
	     let stats =
	       {
		 st_kind = kind;
		 st_perm = 000; (* TODO *)
		 st_nlink = nlink;
		 st_un = un;
		 st_gn = gn;
		 st_size = size;
		 st_mtime = 0.0; (* TODO *)
	       }
	     in
	       (fname, stats)
	   )
	 else
	   (* Printf.printf "ftp - ls: matching failed on: %s (%c)\n" ln ln.[0]; *)
	   raise Unrecognised_format
      ) (list fc path)

let get_file_size fc path =
  (* Let's do it the wget way! *)
  let re = Str.regexp "([ ]*\\([0-9]+\\)[ ]*bytes" in
  let icd, ocd = connect_data fc in
  let r = send_command fc (Retrieve path) in
  let n = fst r in
    if n = 550 then raise Not_found;
    check r;
    (
      try
	stop_reading fc icd;
      with
	| _ -> () (* This is very dirty but it works. *)
    );
    let ln = snd r in
      try
	ignore (Str.search_forward re ln 0);
	int_of_string (Str.matched_group 1 ln)
      with
	| Not_found -> raise Unrecognised_format

(* TODO: improve? *)
let stat fc path =
  let l = ls fc path in
    if List.length l = 0 then
      raise Not_found
    else
      snd (List.hd l)

let mv fc fold fnew =
  csend_command fc (Rename_from fold);
  csend_command fc (Rename_to fnew)

let rm fc f =
  csend_command fc (Delete f)

let rmdir fc d =
  csend_command fc (Remove_directory d)

let mkdir fc d =
  csend_command fc (Make_directory d)

let nop fc =
  csend_command fc Noop


(*** Functions for emulating file manipulations over ftp. ***)


module type FILE =
sig
  val ls : string -> (string * stats) list

  type file_descr
    
  type open_flag =
    | O_RDONLY
    | O_WRONLY
    | O_RDWR

  val openfile : string -> open_flag list -> file_perm -> file_descr

  val close : file_descr -> unit

  val read : file_descr -> string -> int -> int -> int

  type seek_command =
    | SEEK_SET
    | SEEK_CUR
    | SEEK_END

  val lseek : file_descr -> int -> seek_command -> int
end


module File : FILE =
struct
  (* connection, uri, position *)
  type file_descr = ftp_connection * string * (int ref) * in_channel option ref * out_channel option ref

  type open_flag =
    | O_RDONLY
    | O_WRONLY
    | O_RDWR

  let get_server_and_path uri =
    let uri =
      if String.length uri < 6 then
	"ftp://" ^ uri
      else if String.sub uri 0 6 = "ftp://" then
	uri
      else
	"ftp://" ^ uri
    in
    let r = Str.regexp "^ftp://\\(\\([^:]+\\)\\(:\\(.*\\)\\)?@\\)?\\([^:/]+\\)\\(:\\([0-9]+\\)\\)?\\(/.*\\)?" in
       if Str.string_match r uri 0 then begin
	 let user = 
	   try Str.matched_group 2 uri 
	   with Not_found -> "anonymous" in
	 let pass = 
	   try Str.matched_group 4 uri 
	   with Not_found -> "ocaml-ftp@savonet.sf.net" in
	 let host = (* no try .. with, because host name is mandatory *)
	   Str.matched_group 5 uri in
	 let port =
	   try int_of_string(Str.matched_group 7 uri)
	   with Not_found -> 21 in
	 let path =
	   try Str.matched_group 8 uri
	   with Not_found -> "/" in
	   host,port,user,pass,path
       end
       else
	 raise Unrecognised_format

  let ls uri =
    let srv, port, user, pass, path = get_server_and_path uri in
      let conn = connect srv port user pass in
	let ret = ls conn path in
	  disconnect conn; ret

  let openfile fname flags perms =
    let srv, port, user, pass, path = get_server_and_path fname in
    let conn = connect srv port user pass in
      conn, path, ref 0, ref None, ref None

  let may f = function
    | Some x -> f x
    | None -> ()

  let close fd =
    let conn, _, _, ic, oc = fd in
      may (fun ic -> stop_reading conn ic) !ic;
      may close_out !oc; (* TODO: stop_writing *)
      disconnect conn

  let read fd buf ofs len =
    let conn, path, pos, ic, oc = fd in
      may close_out !oc;
      oc := None;
      let i_c =
	(
	  match !ic with
	    | Some ic -> ic
	    | None ->
		let c = start_reading conn path !pos in
		  ic := Some c; c
	) in
      let read =
	try
	  input i_c buf ofs len
	with
	  | Sys_error("Connection reset by peer") ->
	      stop_reading conn i_c;
	      let c = start_reading conn path !pos in
		ic := Some c;
		input c buf ofs len
      in
	pos := !pos + read;
	read

  type seek_command =
    | SEEK_SET
    | SEEK_CUR
    | SEEK_END

  let lseek fd ofs sc =
    let c, p, i, ic, oc = fd in
      may (fun ic -> stop_reading c ic) !ic;
      ic := None;
      may close_out !oc; (* TODO: stop_writing *)
      oc := None;
      i :=
      (
	match sc with
	  | SEEK_SET -> ofs
	  | SEEK_CUR -> !i + ofs
	  | SEEK_END ->
	      (
		try
		  get_file_size c p + ofs
		with
		  | Not_found -> -1
	      )
      ); !i
end
