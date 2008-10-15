val get_nick : unit -> string

val script_audi : string ref

val load_plugins : unit -> unit

val start : unit -> unit

class type t =
object
  method say : string -> string -> unit

  method alive : int list

  method metadatas : string -> (string * string) list list

  method push : string -> string -> unit

  method say_metadata : string -> (string * string) list -> unit

  method skip : string -> unit

  method uptime : string

  method version : string
end

val add_public_message_handler : Str.regexp -> (t -> string -> string -> unit) -> unit
