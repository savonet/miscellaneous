(*
 * Copyright 2008 Savonet team
 *
 * This file is part of ocaml-gsm.
 *
 * ocaml-gsm is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * ocaml-gsm is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with ocaml-gsm; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *)

open Gsm
open Unix

let src = ref ""
let dst = ref ""

let input_string chan len =
  let ans = String.create len in
    (* TODO: check length *)
    ignore (input chan ans 0 len) ;
    ans

let input_int chan =
  let buf = input_string chan 4 in
    (int_of_char buf.[0])
    + (int_of_char buf.[1]) lsl 8
    + (int_of_char buf.[2]) lsl 16
    + (int_of_char buf.[3]) lsl 24

let input_short chan =
  let buf = input_string chan 2 in
    (int_of_char buf.[0]) + (int_of_char buf.[1]) lsl 8

let output_int chan n =
  output_char chan (char_of_int ((n lsr 0) land 0xff));
  output_char chan (char_of_int ((n lsr 8) land 0xff));
  output_char chan (char_of_int ((n lsr 16) land 0xff));
  output_char chan (char_of_int ((n lsr 24) land 0xff))


let output_short chan n =
  output_char chan (char_of_int ((n lsr 0) land 0xff));
  output_char chan (char_of_int ((n lsr 8) land 0xff))

let verbose = ref false
let fast    = ref false
let usage = "usage: transcode [options] source destination"

let _ =
  Arg.parse
    [
      "--verbose", Arg.Bool (fun b -> verbose := b),
      "Verbose encoding" ;
      "--fast", Arg.Bool (fun b -> fast := b),
      "Fast encoding" ;
    ]
    (
      let pnum = ref (-1) in
        (fun s -> incr pnum; match !pnum with
           | 0 -> src := s
           | 1 -> dst := s
           | _ -> Printf.eprintf "Error: too many arguments\n"; exit 1
        )
    ) usage;
  let ic = open_in_bin !src in
  let oc = open_out_bin !dst in
  (* TODO: improve! *)
    if input_string ic 4 <> "RIFF" then invalid_arg "No RIFF tag";
    let ilen = input_int ic in
    if input_string ic 4 <> "WAVE" then invalid_arg "No WAVE tag";
    if input_string ic 4 <> "fmt " then invalid_arg "No fmt tag";
    let _ = input_int ic in
    let _ = input_short ic in (* TODO: should be 1 *)
    let channels = input_short ic in
    assert(channels = 1);
    let infreq = input_int ic in
    assert(infreq = 8000);
    let ibyts = input_int ic in (* bytes / s *)
    let iblal = input_short ic in (* block align *)
    let ibts = input_short ic in
    if input_string ic 4 <> "data" then invalid_arg "No data tag";
    let data_len = input_int ic in
    let fos buf =
      let len = String.length buf / 2 in
      let ans = Array.create len 0 in
        for i = 0 to len - 1 do
          let n =
            int_of_char buf.[2 * i]
            + int_of_char buf.[2 * i + 1] lsl 8
          in
          let n =
            if n land 1 lsl 15 = 0 then
              n
            else
              (n land 0b111111111111111) - 32768
          in
           ans.(i) <- n;
        done;
        ans
    in
      output_string oc "RIFF";
      output_int oc ilen; (* Assume decompression is idempotent in size.. *)
      output_string oc "WAVE";
      output_string oc "fmt ";
      output_int oc 16;
      output_short oc 1; (* WAVE_FORMAT_PCM *)
      output_short oc 1; (* channels *)
      output_int oc infreq; (* freq *)
      output_int oc ibyts; (* bytes / s *)
      output_short oc iblal; (* block alignment *)
      output_short oc ibts; (* bits per sample *)
      output_string oc "data";
      output_int oc data_len;
      let enc = init () in
      if !verbose then
        set enc Verbose 1;
      if !fast then
        set enc Fast 1;
      begin try while true do
            let buflen = signal_frame_size*2 in
            let buf = String.create buflen in
            really_input ic buf 0 buflen; 
            let fbuf = fos buf in
            let ebuf = encode enc fbuf in
            let decbuf = decode enc ebuf in
            Array.iter (fun x -> output_short oc x) decbuf
          done
        with
          | _ -> ()
      end;
      close_in ic; close_out oc;
      Gc.full_major ()
