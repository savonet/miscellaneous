(*
 * Copyright 2003-2004 Savonet team
 *
 * This file is part of OCaml-fetch.
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
  * Copy files through various protocols, given uris.
  *
  * @author Samuel Mimram
  *)

(* $Id$ *)

let usage = "usage: ufetch file [file ...] destination"

let timeout = ref (-1)
let verbose = ref true

let get_supported_protocols () =
  let l = List.fold_left (fun s p -> s ^ "; \"" ^ p ^ "\"") "" (Fetch.supported_protocols ()) in
    String.sub l 2 ((String.length l) - 2)

(* TODO: add -v and --version *)
let _ =
  let src = ref [] in
    Arg.parse
      [
        "--supported-protocols", Arg.Unit (fun () -> Printf.printf "%s\n%!" (get_supported_protocols ()); exit 0), "List the supported protocols";
        "--timeout", Arg.Set_int timeout, "Set a timeout for downloads" ;
        "--quiet", Arg.Clear verbose, "Disable output"
      ] (fun s -> src := s::!src) usage;
    let src,dst =
      match !src with
        | dst::rev when List.length rev > 0 -> (List.rev rev),dst
        | _ -> Printf.eprintf "%s\n" usage; exit 1
    in
      if !verbose then begin
        List.iter (fun s -> print_string s ; print_newline ()) src;
        print_string dst; print_newline ()
      end ;

      let filize src =
        let localize s =
          if String.contains s ':'
          then s
          else "file://"^s
        in
        let src = localize src in
        let dst = localize dst in
        let dst =
          if false (* TODO dist is a dir *) then
            let dst =
              if dst.[(String.length dst) - 1] = '/'
              then dst else dst ^ "/"
            in
              dst ^ (Filename.basename src)
              else dst
        in
          (src,dst)
      in
      let to_cp = List.map filize src in
        if !verbose then
          Sys.set_signal Sys.sigalrm
            (Sys.Signal_handle
              (fun _ -> Printf.printf "Timeout!\n" ; exit 1)) ;
        if (!timeout > 0) then
          ignore (Unix.alarm !timeout) ;
        if !verbose then Printf.printf "Copying file(s)... %!";
        List.iter (fun (s, d) -> Fetch.cp s d) to_cp;
        if !verbose then Printf.printf "done\n%!"
