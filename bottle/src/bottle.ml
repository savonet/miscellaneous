open Irc

let log_irc = ref false
let detach = ref false
let chan = ref "#savonet"
let chan_pass = ref ""
let nick = ref "bottle"
let nick_pass = ref "bottlepass"
let host = ref "irc.freenode.net"
let log_file = ref "/var/log/bottle.log"
let pid_file = ref "/var/run/bottle.pid"
let liq_host = ref "localhost"
let liq_port = ref 1234
let say_color = ref 3
let liq_chan = ref ""
let liq_queue = ref ""
let script_audi = ref "" (* TODO: should not be here but in plugins *)
let plugins = ref []

let log_fun = ref (Printf.printf "%s%!")

let log s = !log_fun s

let get_nick () = !nick

let () =
  Arg.parse
    [
      "-c", Arg.Set_string chan, "irc channel";
      "-f", Arg.Set detach, "detach daemon";
      "-lc", Arg.Set_string liq_chan, "default liquisoap channel";
      "-lh", Arg.Set_string liq_host, "liquidsoap host";
      "-lp", Arg.Set_int liq_port, "liquidsaop port";
      "-lq", Arg.Set_string liq_queue, "default liquidsoap queue";
      "-n", Arg.Set_string nick, "nickname";
      "-np", Arg.Set_string nick_pass, "password for the nickname";
      "-p", Arg.String (fun s -> plugins := !plugins@[s]), "load plugin";
      "-sa", Arg.Set_string script_audi, "script to get audimat";
      "-v", Arg.Set log_irc, "be verbose"
    ]
    (fun s -> ())
    "bottle options"

let rec re_assoc s = function
  | (r, x)::_ when (Str.string_match r s 0) -> x
  | _::t -> re_assoc s t
  | [] -> raise Not_found

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

class bottle =
object (self)
  val mutable liq = Liq.connect !liq_host !liq_port

  method liq_reconnect =
    (
      try
        Liq.disconnect liq
      with
        | _ -> ()
    );
    liq <- Liq.connect !liq_host !liq_port

  method safe_liq : 'a. (unit -> 'a) -> 'a =
    fun f ->
      try
        f ()
      with
        | End_of_file
        | Sys_error("Broken pipe") ->
            (
              try
                self#liq_reconnect;
                Printf.printf "[DD] Connection error!\n%!";
                (* f () *)
                raise Liq.Liq_error
              with
                | _ ->
                    Printf.printf "[DD] Connection error! (bis)\n%!";
                    raise Liq.Liq_error
            )

  method on_air =
    self#safe_liq (fun () -> Liq.on_air liq)

  method metadata =
    self#safe_liq (fun () -> Liq.metadata liq)

  method metadatas chan =
    self#safe_liq (fun () -> Liq.metadatas liq (if chan = "" then !liq_chan else chan))

  method push queue file =
    self#safe_liq (fun () -> Liq.push liq (if queue = "" then !liq_queue else queue) file)

  method uptime =
    self#safe_liq (fun () -> Liq.uptime liq)

  method skip chan =
    self#safe_liq (fun () -> Liq.skip liq (if chan = "" then !liq_chan else chan))

  method alive =
    self#safe_liq (fun () -> Liq.alive liq)

  method version =
    self#safe_liq (fun () -> Liq.version liq)

  inherit client !host !nick !nick !nick "savonet.sf.net" as super

  initializer self#set_port 7000

  method load_plugins =
    try
      List.iter self#load_plugin !plugins
    with
      | Dynlink.Error e -> Printf.printf "[EE] Dynlink error: %s\n%!" (Dynlink.error_message e)

  method load_plugin p =
    Dynlink.loadfile p

  method identify pass =
    super#say "nickserv" ("identify " ^ pass)

  method say dst msg =
    super#say dst (if !say_color >= 0 then color_text !say_color msg else msg)

  method on_raw_event msg =
    if !log_irc then
      log (Printf.sprintf "%s%!" msg);
    super#on_raw_event msg

  method on_kick sender chan user reason =
    if user = !nick then
      self#join chan

  method on_ctcp_ping_reply sender receiver timestamp =
    let time = Unix.gettimeofday() in
      try
        self#notice (string_of_sender sender) (Printf.sprintf "(Meta-Ping) You are lagging of %.3f seconds." (time -. (float_of_string timestamp)))
      with
        | _ -> ()

  method say_metadata dst metadata =
    let get_field f =
      try
        let ans = List.assoc f metadata in
          (* TODO *)
          Str.global_replace (Str.regexp "\n") "" ans
      with
        | _ -> ""
    in
      let rid = get_field "rid" in
      let artist = get_field "artist" in
      let title = get_field "title" in
        self#say dst (rid ^ ": " ^ artist ^ " - " ^ title)

  val mutable public_message_handler = []

  method add_public_message_handler (re:Str.regexp) (f:t -> string -> string -> unit) =
    public_message_handler <- (re, f)::public_message_handler

  method on_message sender receiver msg =
    let priv_msg_handler =
      [
        "help",
        (fun orig dst ->
           self#say dst "Bottle: the bot of savonet (http://savonet.sf.net/)";
           self#say dst "- alive";
           self#say dst "- audi";
           self#say dst "- filename";
           self#say dst "- help";
           self#say dst "- metadatas [chan]";
           self#say dst "- on air";
           self#say dst "- ping";
           self#say dst "- play";
           self#say dst "- prev [n] [chan]";
           self#say dst "- uptime";
           self#say dst "- version";
        )
      ]
    in
    let priv_msg_handler =
      List.map (fun (r, f) -> Str.regexp r, f) priv_msg_handler
    in
      ignore
        (Thread.create
           (fun () ->
              if receiver = !nick then
                (re_assoc msg priv_msg_handler) msg (string_of_sender sender)
              else
                let dst =
                  if receiver = !nick then
                    string_of_sender sender
                  else
                    receiver
                in
                  try
                    (re_assoc msg public_message_handler) (self :> t) msg dst
                  with
                    | Liq.Liq_error -> self#say dst "error while communicating with liquidsoap"
           )
           ()
        )
end

let irc = new bottle

let add_public_message_handler = irc#add_public_message_handler

let load_plugins () =
  Dynlink.init ();
  irc#load_plugins

let start () =
  (
    if !detach then
      (
        flush_all ();
        close_in stdin;
        close_out stdout;
        close_out stderr;
        if Unix.fork () = 0 && Unix.fork () = 0 then
          ignore (Unix.setsid ())
        else
          exit 0;
        let pf = open_out !pid_file in
        let lf = open_out !log_file in
          log_fun := (fun s -> output_string lf s; flush lf);
          output_string pf (Printf.sprintf "%d\n" (Unix.getpid ()));
          close_out pf
      )
  );
  Sys.set_signal Sys.sigpipe Sys.Signal_ignore;
  while true
  do
    try
      irc#connect;
      if !nick_pass <> "" then irc#identify !nick_pass;
      irc#join !chan;
      irc#say !chan "lo";
      irc#event_loop
    with
      | e ->
          log (Printf.sprintf "Exn: %s\n\n%!" (Printexc.to_string e));
          Unix.sleep 60;
          log (Printf.sprintf "Rejoining...\n%!")
  done
