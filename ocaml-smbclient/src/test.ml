(**
  Testing ocaml-smbclient functions...

  @author Gaétan Richard, Samuel Mimram
*)

(* $Id$ *)

open Smbclient

let auth user pass = ("REZO","name","pass")

let _ = Smbclient.init auth

let _ =
  let fname = "smb://FOOTWAR/Mp3/misc/Laetitia.mp3" in
  let fd = Smbclient.openfile fname [O_RDONLY] 600 in
    Printf.printf "lseek : %d\n" (Smbclient.lseek fd 10 SEEK_SET);
    List.iter (fun s -> Printf.printf "%s | " s) (get_servers "smb://REZO")
  

(*
let url0 = "smb://FOOTWAR/Mp3"
let i=ref 0 
let j=ref 0 
let k=ref 0 

let rec space n =
  match n with 
    | 0 -> ""
    | _ -> "   "^space(n-1)


let rec explore url n = 
  try
    begin
      let chan = Smbclient.open_dir url in 
	try
	  while true do
	    let s0 = Smbclient.read_dir chan in
	    let s = s0.Smbclient.name and s1= s0.Smbclient.kind in
	      if (s<>"." && s<>"..") then
		begin
		  Printf.printf "%s%d:%s\n" (space n) (Obj.magic s1) s;
		  explore (url^"/"^s) (n+1);
		end
	  done
	with
	  | _ -> 
	      Smbclient.close_dir chan
    end
  with
    | _ -> ()

let _ = 
  Smbclient.init auth;
  explore url0 0
      
*)
