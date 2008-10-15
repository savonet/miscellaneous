type t

external get_version : unit -> string * string = "ocaml_faac_get_version"

external create : int -> int -> t * int * int = "ocaml_faac_open"

external close : t -> unit = "ocaml_faac_close"

external set_configuration : t -> int option -> int option -> int option -> int option -> unit = "ocaml_faac_set_configuration"

let set_configuration eh ?mpeg_version ?quality ?bitrate ?bandwidth () =
  set_configuration eh mpeg_version quality bitrate bandwidth

external encode : t -> float array -> int -> int -> string -> int -> int = "ocaml_faac_encode_byte" "ocaml_faac_encode"

(* Non-interleaved version. *)
let encode_ni eh inbuf inbufofs inbuflen =
  let chans = Array.length inbuf in
  let buf = Array.make (chans*inbuflen) 0. in
    for i = 0 to inbuflen - 1 do
      for c = 0 to chans - 1 do
        buf.(chans * i + c) <- inbuf.(c).(i+inbufofs)
      done
    done;
    encode eh buf 0 (chans*inbuflen)
