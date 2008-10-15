(**
  * Bindings to the jack audio connexion kit.
  *
  * @author Samuel Mimram
  *)

(* $Id$ *)

(** An error occured... *)
exception Jack_error of int

(** Set the callback function called on error, with the error message as
  * argument. *)
val set_error_function : (string -> unit) -> unit

(** Get the size of a sample (in bytes). *)
val get_sample_size : unit -> int

(** Lock-free ringbuffers. **)
module Ringbuffer : sig
  (** Type for ringbuffers. *)
  type t

  (** Create a ringbuffer of the specified size (in bytes). *)
  val create : int -> t

  exception Mlock_failed

  (** Lock a ringbuffer data block into memory. *)
  val mlock : t -> unit

  (** [read rb buf ofs len] try to read [len] bytes in the ringbuffer [rb] and
    * put them in [buf] starting at position [ofs]. The actual number of bytes
    * read is returned.
    *)
  val read : t -> string -> int -> int -> int

  (** Get the number of bytes available for reading. *)
  val read_space : t -> int

  (** Advance the read pointer. *)
  val read_advance : t -> int -> unit

  (** Reset the read and write pointers, making an empty buffer. *)
  val reset : t -> unit

  (** [write rb buf ofs len] tries to take [len] bytes in [buf], starting at
    * position [ofs], and put them in the ringbuffer [rb]. The actual number of
    * bytes written is returned.
    *)
  val write : t -> string -> int -> int -> int

  (** Get the numbfer of bytes available for writing. *)
  val write_space : t -> int

  (** Advance the write pointer. *)
  val write_advance : t -> int -> unit

  (** 32 bits floats ringbuffers. *)
  module Float : sig
    type t

    val create : int -> t

    (** Read data as 32 bits floats. The arguments are similar to those of [read]
      * but are expressed in number of floats instead of bytes. *)
    val read : t -> float array -> int -> int -> int

    val read_space : t -> int

    val read_advance : t -> int -> unit

    val write : t -> float array -> int -> int -> int

    val write_space : t -> int

    val write_advance : t -> int -> unit
  end with type t = t
end

(** Jack ports. *)
module Port :
sig
  (** Type for ports. *)
  type t

  (** Get the full name of a port (including the "client_name:" prefix). *)
  val name : t -> string

  val set_name : t -> string -> unit

  (** Get the short  name of a port (not including the "client_name:" prefix). *)
  val short_name : t -> string

  type flags =
    | Input (* input port (can receive data) *)
    | Output (* output port (can send data) *)
    | Physical (* physical port *)
    | Can_monitor (* port with monitoring capability *)
    | Terminal (* terminal port *)

  (** Get the flags associated to a port. *)
  val flags : t -> flags list

  (** Get port type. *)
  val port_type : t -> string

  (** Number of connections from/to a port. *)
  val connected : t -> int

  (** Is this port directly connected to another given port? *)
  val connected_to : t -> string -> bool

  (** Default type for audio ports. Currently, it is 32 bits float, mono. *)
  val default_audio_type : string

  val set_latency : t -> int -> unit
end

(** Jack clients. *)
module Client :
sig
  (** Type for jack clients. *)
  type t

  (** An error occured while creating the client. *)
  exception Creation_error

  (** Create a new jack client with a given name. *)
  val create : string -> t

  (** Close a jack client. *)
  val close : t -> unit

  (** Check if the jack system is running in realtime mode (-R). *)
  val is_realtime : t -> bool

  (** Retrieve the maximal buffer size (in samples) allowed. *)
  val get_buffer_size : t -> int

  type direction =
    | Read (* read into the ringbuffer *)
    | Write (* write into the ringbuffer *)

  (** Set which ringbuffers should be filled in/out at each processing callback. *)
  val set_process_ringbuffer_callback : t -> (Port.t * Ringbuffer.t * direction) list -> unit

  exception Stop_processing

  val process : t -> (unit -> unit) -> unit

  (** Tell the Jack server that the client is ready to start processing audio. *)
  val activate : t -> unit

  (** Tell the Jack server to remove this client from the process graph. Also,
    * disconnect all ports belonging to it, since inactive clients have no port
    * connections. *)
  val deactivate : t -> unit

  (** Set a callback function called when jack is shut down. *)
  val on_shutdown : t -> (unit -> unit) -> unit

  (** Register a port with a given name, audio type (usually
    * [Port.default_audio_type]), flags and buffer size (in bytes). *)
  val register_port : t -> string -> string -> Port.flags list -> int -> Port.t

  (** [connect client src dst] connects the port nammed [src] with the port
    * nammed [dst]. *)
  val connect : t -> string -> string -> unit

  (** Disconnect a port from another port. *)
  val disconnect : t -> string -> string -> unit

  (** Get a port given its name. *)
  val port_by_name : t -> string -> Port.t

  (** Get all jack ports. *)
  val get_ports : t -> string list

  (** Get all the connections of a port. *)
  val get_port_all_connections : t -> Port.t -> string list

  (** Retrieve the sample rate of the jack system (in frames/sec). *)
  val get_sample_rate : t -> int

  (** Retrieve the CPU load. *)
  val get_cpu_load : t -> float

  val frame_time : t -> int

  val frames_since_cycle_start : t -> int
end

module Stats :
sig
  val get_max_delayed : Client.t -> float

  val reset_max_delayed : Client.t -> unit

  val get_xrun_delayed : Client.t -> float
end

module Transport :
sig
  val start : Client.t -> unit

  val stop : Client.t -> unit
end
