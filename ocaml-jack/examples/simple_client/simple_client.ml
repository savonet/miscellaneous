open Jack

let log s =
  Printf.eprintf s

let client_name = ref ("simple_client [" ^ string_of_int (Unix.getpid ()) ^ "]")

let on_shutdown () =
  log "(WW) Jack was shut down.\n%!"

let error_callback err =
  log "(EE) %s\n%!" err;
  exit 1

let connection = ref ""
let dump = ref false

let () =
  Arg.parse
    [
      "-c", Arg.Set_string connection, "port to connect to";
      "-d", Arg.Set dump, "dump to stdout"
    ]
    (fun _ -> ())
    "usage: simple_client [options]";
  set_error_function error_callback;
  let client = Client.create !client_name in
  let buflen = Client.get_buffer_size client in
  let inbuf = Ringbuffer.Float.create (buflen * 4) in
  let inp = Client.register_port client "in_0" Port.default_audio_type [Port.Input] 0 in
    Client.on_shutdown client on_shutdown;
    log "(II) Engine sample rate: %d\n%!" (Client.get_sample_rate client);
    log "(II) Engine sample size: %d\n%!" (get_sample_size ());
    if !dump then
      let buf = String.create (get_sample_size () * buflen) in
        Client.set_process_ringbuffer_callback
          client [inp, inbuf, Client.Write];
        Client.activate client;
        if !connection <> "" then
          Client.connect client !connection "simple_client:in_0";
        Client.process client
          (fun () ->
             while Ringbuffer.read_space inbuf > 0 do
               let n = Ringbuffer.read inbuf buf 0 buflen in
                 output stdout buf 0 n
             done)
    else
      let buf = Array.create buflen 0. in
      let outbuf = Ringbuffer.Float.create (buflen * 4) in
      let outp =
        Client.register_port client
          "out_0" Port.default_audio_type [Port.Output] 0
      in
        Client.set_process_ringbuffer_callback
          client [inp, inbuf, Client.Write; outp, outbuf, Client.Read];
        Client.activate client;
        if !connection <> "" then
          Client.connect client !connection "simple_client:in_0";
        Client.process client
          (fun () ->
             while Ringbuffer.read_space inbuf > 0 do
               let n = Ringbuffer.Float.read inbuf buf 0 buflen in
                 (* Insert any processing on the array of float samples.. *)
                 assert ((Ringbuffer.Float.write outbuf buf 0 n) = n)
             done);
        Gc.full_major ()
