(*****************************************************************************

  Liquidsoap, a programmable audio stream generator.
  Copyright 2003-2008 Savonet team

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details, fully stated in the COPYING
  file at the root of the liquidsoap distribution.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

 *****************************************************************************)

  (**
    * {R {i {v Natty natty, never get weary... v}  }  }
    * {R {b Culture }}
    *
    * {2 Multimedia parser for OCaml.}
    *
    * {!Natty} is a set of multimedia parsers for ocaml. It can read various
    * multimedia formats.
    *
    * However, {!Natty} doesn't do any audio or video processing. It is aimed
    * at reading and extracting data from various multimedia
    * formats/containers.
    *
    * It is implemented using the [Bitstring] module.*)

(** Raised when no known format or container could be found. *)
exception Unknown_format

type endianess = Big_endian | Little_endian
  and
     pcm_data =
  {
    channels        : int;
    sample_rate     : int;
    bits_per_sample : int;
    endianess       : endianess
  }
  and
    video_params = 
  {
    width  : int;
    height : int
  }
  and
     audio_codec = Pcm of pcm_data | Mp3 | Audio_fourcc of string | Unknown
  and
     video_codec = Video_fourcc of string*(video_params option) | Unknown

(** All functions in the following modules 
  * may raise [Failure x] if a hard failure
  * occured. x is then the failure explanation. *)

module Au : 
sig

  type t = 
    { data : Bitstring.bitstring ref;
      format      : audio_codec;
      length      : float option 
    }

  (** Open an Au audio file.
    * 
    * raises [Natty.Unknown_format] if the file 
    * is not an Au file. *)
  val open_f : string -> t

  (** Get samples from an Au file.
    *
    * Returned samples are then definitely 
    * removed.
    *
    * raises [Not_found] if there aren't enough 
    * samples available. *)
  val get_samples : t -> int -> string

  (** Get all samples from an Au file *)
  val get_all_samples : t -> string

end

module Wav : 
sig

  type t =
    { data : Bitstring.bitstring ref;
      format      : audio_codec;
      length      : float option
    }

  (** Open a Wav audio file.
    *
    * raises [Natty.Unknown_format] if the file
    * is not an Au file. *)
  val open_f : string -> t

  (** Get samples from a Wav file.
    *
    * Returned samples are then definitely
    * removed.
    *
    * raises [Not_found] if there aren't enough
    * samples available. *)
  val get_samples : t -> int -> string

  (** Get all samples from a Wav file *)
  val get_all_samples : t -> string

end

module Aiff : 
sig

  (** Raised when the end of file has been reached. *)
  exception Eof
  
  type compression = 
     { id   : string;
       name : string }
   and
       comm_data = 
     { num_chans       : int;
       num_frames      : int;
       bitspersample   : int; 
       samplerate      : float;
       compression     : compression option }
   and
       ssnd_data = 
    { comment : string;
      audio   : Bitstring.bitstring }
   and
       appl_data = 
    { signature : string;
      content   : string }
   and
      chunk = 
   | Comm of comm_data
   | Ssnd of ssnd_data
   | Fver of Int64.t
   | Form of string
   | Appl of appl_data
   | Auth of string
   | Name of string
   | Copyright of string
   | Anno of string
   | Inst of string
   | Mark of string
   | Skip of string
  
  type t =
    { ssnd     : Bitstring.bitstring ref;
      format   : audio_codec;
      length   : float option;
      chunks   : chunk list ref;
      rem_bits : Bitstring.bitstring ref
    }

  (** Open an Aiff audio file.
    *
    * raises [Natty.Unknown_format] if the file
    * is not an Au file. *)
  val open_f : string -> t

  (** Get a chunk from an Aiff file.
    *
    * raises [Natty.Aiff.Eof] if the 
    * end of file has been reached. *)
  val get_chunk : t -> chunk

  (** Get samples from an Aiff file.
    *
    * Returned samples are then definitely
    * removed.
    *
    * raises [Not_found] if there aren't enough
    * samples available. *)
  val get_samples : t -> int -> string

  (** Get all samples from an Aiff file *)
  val get_all_samples : t -> string

end

module Nsv : 
sig

  type chunk = 
    { label   : string;
      content : string }
    and
       payload = 
    { audio  : string;
      video  : string;
      chunks : chunk list }
    and
       frame_header = 
      Sync of (audio_codec option)*video_codec
    | Async
    and
       frame = frame_header*payload
  
  type t = 
    { data     : Bitstring.bitstring ref;
      metadata : string;
      toc      : string;
      format   : (audio_codec option)*video_codec;
    }    

  (** Open a Nsv audio file.
    *
    * raises [Natty.Unknown_format] if the file
    * is not a Nsv file. *)
  val open_f : string -> t

  (** Get a frame from a Nsv file
    *
    * The frame is then definitely 
    * removed.
    *
    * Raises [Not_found] if no frames
    * could be found. *)
  val get_frame : t -> frame

end
