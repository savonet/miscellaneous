(**
  * Testing the ocaml-fetch module...
  *
  * @author Samuel Mimram, Florent Becker
  *)

(* $Id$ *)

open Fetch

(*
let testls_samba ()=
  init_samba "REZO" "toto" "";
  let servers =  (Smbclient.get_servers "smb://REZO") in
    List.iter (
      fun s ->
	try
	  Printf.printf "%s\n%!" s;
	  let contents = ls ("smb://"^s) in
	    List.iter 
	      (function
		 |  Fetch.Fk_regular s ->  Printf.printf "reg:%s\n%!" s
		 |  Fetch.Fk_dir s ->    Printf.printf "dir:%s\n%!" s)
	      contents
	with Smbclient.No_file -> ()
  ) servers
*)

let testls ()=
  let contents = ls ("ftp://localhost") in
    List.iter
      (function
         | Fetch.Fk_regular s -> Printf.printf "reg:%s\n%!" s
         | Fetch.Fk_dir s -> Printf.printf "dir:%s\n%!" s
      ) contents

let testftp () =
  let fd = openfile "ftp://localhost/welcome.msg" [O_RDONLY] 644 in
  let buf = String.create 100 in
    ignore (read fd buf 0 30);
    Printf.printf "read: %s\n" buf;
    let p1 = lseek fd 0 SEEK_CUR in
    let p2 = lseek fd 0 SEEK_END in
    Printf.printf "pos: %d     size: %d\n" p1 p2;
    close fd

let testcp () =
  Printf.printf "cp... ";
  cp "ftp://babasse/pub/music/mirror.mp3" "file:///tmp/toto.mp3";
  cp "file:///tmp/toto.mp3" "file:///tmp/toto2.mp3";
  Printf.printf "ok\n"

let _ =
  testls ();
  testftp ();
  testcp ()
