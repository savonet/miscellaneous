(*
 * Copyright 2003-2006 Savonet team
 *
 * This file is part of Ocaml-gsm.
 *
 * Ocaml-gsm is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Ocaml-gsm is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Ocaml-gsm; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *)

(**
  * Functions for decoding and encoding gsm data using libgsm.
  *
  * @author Romain Beauxis
  *)

let signal_frame_size = 160
let encoded_string_size = 33

exception Wrong_size

type t

type option = 
    Verbose 
  | Fast
  | Ltp_cut
  | Wav49
  | Frame_index
  | Frame_chain

let int_of_option o = 
  match o with
    | Verbose -> 1
    | Fast -> 2
    | Ltp_cut -> 3
    | Wav49 -> 4
    | Frame_index -> 5
    | Frame_chain -> 6

external init : unit -> t = "ocaml_gsm_init"

external get : t -> int -> int = "ocaml_gsm_get"

let get e o = 
  get e (int_of_option o)

external set : t -> int -> int -> unit = "ocaml_gsm_set"

let set e o v =
  set e (int_of_option o) v

external encode : t -> int array -> string = "ocaml_gsm_encode"

let encode e s = 
  if Array.length s <> signal_frame_size then
    raise Wrong_size;
  encode e s

external decode : t -> string -> int array = "ocaml_gsm_decode"

let decode e s = 
  if String.length s <> encoded_string_size then
    raise Wrong_size;
  decode e s

