(*
 Copyright 2003-2006 Savonet team

 This file is part of OCaml-Shout.

 OCaml-Shout is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 OCaml-Shout is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with OCaml-Shout; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *)

(**
  * Send a file to an icecast2 server.
  *
  * @author Samuel Mimram
  *)

let file = ref []
let host = ref "localhost"
let port = ref 8000
let pass = ref "hackme"
let mount = ref "test.ogg"
let user = ref "source"
let bufsize = ref (1024 * 8)

let usage = "usage: shoutfile [options] files"

let _ =
  Arg.parse
    [
      "-h", Arg.String (fun s -> host := s), "\thost";
      "-m", Arg.String (fun s -> mount := s), "\tmountpoint";
      "-p", Arg.Int (fun i -> port := i), "\tport";
      "-s", Arg.String (fun s -> pass := s), "\tpassword";
      "-u", Arg.String (fun s -> user := s), "\tuser";
    ]
    (fun s -> file := s::!file)
    usage;
  if !file = [] then
    (
      Printf.printf "%s\n" usage;
      exit 1
    );
  Shout.init ();
  let ver, v_maj, v_min, v_patch = Shout.version () in
    Printf.printf "Using libshout %s (%d.%d.%d)\n\n%!" ver v_maj v_min v_patch;
    Printf.printf "Connecting to server... %!";
    let shout = Shout.new_shout () in
      Shout.set_host shout !host;
      Shout.set_protocol shout Shout.Protocol_http;
      Shout.set_port shout !port;
      Shout.set_password shout !pass;
      Shout.set_mount shout !mount;
      Shout.set_user shout !user;
      Shout.set_format shout
        (
          let l = String.length (List.hd !file) in
            if l < 4 then failwith "unknown file format";
            match String.sub (List.hd !file) (l - 4) 4 with
              | ".ogg" -> Shout.Format_vorbis
              | ".mp3" -> Shout.Format_mp3
              | _ -> failwith "unknown file format"
        );
      Shout.set_description shout (List.hd !file);
      Shout.open_shout shout;
      Printf.printf "done\n%!";

      Printf.printf "\n";
      let buf = String.create !bufsize in
      let pos = ref 0 in
        while !file <> [] do
          let ic = open_in (List.hd !file) in
            try
              while true
              do
                Printf.printf "\rDelay before next send: %d ms%!" (Shout.delay shout);
                let read = input ic buf !pos (!bufsize - !pos) in
                  pos := (!pos + read) mod !bufsize;
                  if !pos = 0 then begin
                    Shout.sync shout; Shout.send shout buf
                  end
                  else if read = 0 then (close_in ic; raise End_of_file)
              done;
            with
              | End_of_file ->
                  print_string "\nFile sent.\n%!"; file := List.tl !file
        done;
        Shout.close shout;
        Shout.shutdown ()
