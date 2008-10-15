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

val signal_frame_size : int
val encoded_string_size : int

exception Wrong_size

type t

type option = 
    Verbose 
  | Fast
  | Ltp_cut
  | Wav49
  | Frame_index
  | Frame_chain

val init : unit -> t

val get : t -> option -> int

val set : t -> option -> int -> unit

val encode : t -> int array -> string

val decode : t -> string -> int array

