(** Internal state of an encoder. *)
type t

(** Get the id and the copyright of the current facc version. *)
val get_version : unit -> string * string

(** [create rate chans] creates a new encoder at [rate] sample rate (in Hz) and
  * with [chans] channels. The two integers returned are respectively the total
  * number of samples that should be feed at each [encode] call and the maximum
  * number of bytes that can be in the output buffer.
  *)
val create : int -> int -> t * int * int

val close : t -> unit

(** [bitrate] is a per-channel bitrate. *)
val set_configuration : t -> ?mpeg_version:int -> ?quality:int -> ?bitrate:int -> ?bandwidth:int -> unit -> unit

(** [encode eh inbuf inofs inlen outbuf outofs] *)
val encode : t -> float array -> int -> int -> string -> int -> int

(** Same as [encode] but take non-interleaved data as input. *)
val encode_ni : t -> float array array -> int -> int -> string -> int -> int
