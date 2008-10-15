(* $Id$ *)

exception Jack_error of int

let () =
  Callback.register_exception "jack_exn_jack_error" (Jack_error 0);
  Callback.register "caml_mutex_create" Mutex.create;
  Callback.register "caml_mutex_lock" Mutex.lock;
  Callback.register "caml_mutex_unlock" Mutex.unlock;
  Callback.register "caml_condition_create" Condition.create;
  Callback.register "caml_condition_signal" Condition.signal

external set_error_function : (string -> unit) -> unit = "ocaml_jack_set_error_function"

external get_sample_size : unit -> int = "ocaml_jack_get_sample_size"

module Ringbuffer =
struct
  type t

  type ringbuffer = t

  external create : int -> t = "ocaml_jack_ringbuffer_create"

  exception Mlock_failed

  let () =
    Callback.register_exception "jack_exn_mlock_failed" Mlock_failed

  external mlock : t -> unit = "ocaml_jack_ringbuffer_mlock"

  external read : t -> string -> int -> int -> int = "ocaml_jack_ringbuffer_read"

  external read_space : t -> int = "ocaml_jack_ringbuffer_read_space"

  external read_advance : t -> int -> unit = "ocaml_jack_ringbuffer_read_advance"

  external reset : t -> unit = "ocaml_jack_ringbuffer_reset"

  external write : t -> string -> int -> int -> int = "ocaml_jack_ringbuffer_write"

  external write_space : t -> int = "ocaml_jack_ringbuffer_write_space"

  external write_advance : t -> int -> unit = "ocaml_jack_ringbuffer_write_advance"

  module Float =
  struct
    type t = ringbuffer

    let create n = create (n * 4)

    external read : t -> float array -> int -> int -> int = "ocaml_jack_ringbuffer_read32f"

    let read_space r = (read_space r) / 4

    let read_advance r n = read_advance r (n * 4)

    external write : t -> float array -> int -> int -> int =  "ocaml_jack_ringbuffer_write32f"

    let write_space r = (write_space r) / 4

    let write_advance r n = write_advance r (n * 4)
  end
end

module Port =
struct
  type t

  external name : t -> string = "ocaml_jack_port_name"

  external set_name : t -> string -> unit = "ocaml_jack_port_set_name"

  external short_name : t -> string = "ocaml_jack_port_short_name"

  type flags = Input | Output | Physical | Can_monitor | Terminal

  external flags : t -> flags array = "ocaml_jack_port_flags"

  let flags p = Array.to_list (flags p)

  external port_type : t -> string = "ocaml_jack_port_type"

  external connected : t -> int = "ocaml_jack_port_connected"

  external connected_to : t -> string -> bool = "ocaml_jack_port_connected_to"

  let default_audio_type = "32 bit float mono audio"

  external set_latency : t -> int -> unit = "ocaml_jack_port_set_latency"
end

module Client =
struct
  type t

  exception Creation_error

  let () =
    Callback.register "jack_exn_client_creation_error" Creation_error

  external create : string -> t = "ocaml_jack_client_new"

  external close : t -> unit = "ocaml_jack_client_close"

  external is_realtime : t -> bool = "ocaml_jack_is_realtime"

  external get_buffer_size : t -> int = "ocaml_jack_get_buffer_size"

  type direction = Read | Write

  external set_process_ringbuffer_callback : t -> (Port.t * Ringbuffer.t * direction) array -> unit = "ocaml_jack_set_process_ringbuffer_callback"

  let set_process_ringbuffer_callback c bufs = set_process_ringbuffer_callback c (Array.of_list bufs)

  external get_process_callback_mutex : t -> Mutex.t = "ocaml_jack_get_process_callback_mutex"

  external get_process_callback_condition : t -> Condition.t = "ocaml_jack_get_process_callback_condition"

  external start_poller : t -> unit = "ocaml_jack_start_poller"

  exception Stop_processing

  let process client f =
    let m = get_process_callback_mutex client in
    let c = get_process_callback_condition client in
      start_poller client;
      try
        while true do
          Mutex.lock m;
          Condition.wait c m;
          f ();
          Mutex.unlock m;
        done
      with
        | Stop_processing -> ()

  external activate : t -> unit = "ocaml_jack_activate"

  external deactivate : t -> unit = "ocaml_jack_deactivate"

  external on_shutdown : t -> (unit -> unit) -> unit = "ocaml_jack_on_shutdown"

  external register_port : t -> string -> string -> Port.flags list -> int -> Port.t = "ocaml_jack_port_register"

  external connect : t -> string -> string -> unit = "ocaml_jack_connect"

  external disconnect : t -> string -> string -> unit = "ocaml_jack_disconnect"

  external port_by_name : t -> string -> Port.t = "ocaml_jack_port_by_name"

  external get_ports : t -> string -> string -> int -> string array = "ocaml_jack_get_ports"

  let get_ports c = Array.to_list (get_ports c "" "" 0)

  external get_port_all_connections : t -> Port.t -> string array = "ocaml_jack_port_get_all_connections"

  let get_port_all_connections c p = Array.to_list (get_port_all_connections c p)

  external get_sample_rate : t -> int = "ocaml_jack_get_sample_rate"

  external get_cpu_load : t -> float = "ocaml_jack_get_cpu_load"

  external frame_time : t -> int = "ocaml_jack_frame_time"

  external frames_since_cycle_start : t -> int = "ocaml_jack_frames_since_cycle_start"
end

module Stats =
struct
  external get_max_delayed : Client.t -> float = "ocaml_jack_get_max_delayed_usecs"

  external reset_max_delayed : Client.t -> unit = "ocaml_jack_reset_max_delayed_usecs"

  external get_xrun_delayed : Client.t -> float = "ocaml_jack_get_xrun_delayed_usecs"
end

module Transport =
struct
  type state =
    | Stopped
    | Rolling
    | Looping
    | Starting

  external start : Client.t -> unit = "ocaml_jack_transport_start"

  external stop : Client.t -> unit = "ocaml_jack_transport_stop"
end
