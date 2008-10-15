(**
  Testing Ftp module functions...

  @author Samuel Mimram
*)

(* $Id$ *)

open Printf

let _ =
  let fc = (* Ftp.connect "babasse" 21 "anonymous" "a@b.com"  *) 
    Ftp.connect "localhost" 21 "anonymous" "test@ocaml-ftp.com"
  in
    printf "cur dir: %s\n" (Ftp.get_cur_dir fc);
    Ftp.get_file fc "welcome.msg" "/tmp/toto";
(*    Ftp.chdir fc "pub/mp3/julio";
    Printf.printf "len: %d\n%!" (Ftp.get_size fc "spinning.mp3");*)
    (*Ftp.chdir fc "pub/music";
      Ftp.get_file fc "Kylie Minogue - Confide in Me.mp3" "toto.mp3";
      printf "cur dir: %s\n" (Ftp.get_cur_dir fc);
      Ftp.get_file fc "mirror.mp3" "toto2.mp3";
      Ftp.nop fc;
    (* printf "ls: %s\n" (List.fold_left (fun r s -> s ^ " | " ^ r) "" (Ftp.ls fc "/pub/music")); *)
      Ftp.nop fc;
    (* printf "ls: %s\n" (List.fold_left (fun r s -> s ^ " | " ^ r) "" (Ftp.list_files fc "/pub/music")); *)
      ignore (Ftp.ls fc "/pub/music");
    (* Ftp.chdir fc "/"; *)
      let buf = String.create 10 in
      let n = Ftp.get_file_portion fc "mirror.mp3" 0 buf 0 10 in
      printf "portion (%d): %s\n" n buf;*)
    Ftp.disconnect fc
