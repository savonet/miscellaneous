let rec list_nth n = function
  | h::_ when n = 0 -> h
  | _::t -> list_nth (n - 1) t
  | [] -> raise Not_found

let pub_msg_handler =
  [
    "say[ ]*\\([A-Za-z ]*\\)", (fun self orig dst -> self#say dst (Str.matched_group 1 orig));
    "metadatas[ ]*\\([a-z.]*\\)",
    (fun self orig dst ->
       List.iter (fun m -> self#say_metadata dst m) (List.rev (self#metadatas (Str.matched_group 1 orig)))
    );
    "prev[ ]*\\([0-9]*\\)[ ]*\\([a-z.]*\\)",
    (fun self orig dst ->
       try
         let n =
           let ns = Str.matched_group 1 orig in
             if ns = "" then 1 else int_of_string ns
         in
           self#say_metadata dst (list_nth n (self#metadatas (Str.matched_group 2 orig)))
       with
         | Not_found -> self#say dst "not found"
    );
    "filename[ ]*\\([a-z.]*\\)",
    (fun self orig dst ->
       try
         self#say dst (List.assoc "filename" (List.hd (self#metadatas (Str.matched_group 1 orig))))
       with
         | Not_found -> self#say dst "not found"
    );
    "play[ ]*\\(.*\\)",
    (fun self orig dst ->
       self#push "" (Str.matched_group 1 orig);
       self#say dst "file queued"
    );
    "skip[ ]*\\([a-z.]*\\)",
    (fun self orig dst ->
       self#skip (Str.matched_group 1 orig);
       self#say dst "skip done"
    );
    "audi",
    (fun self _ dst ->
       if !Bottle.script_audi <> "" then
         let p = Unix.open_process_in !Bottle.script_audi in
           self#say dst (input_line p);
           ignore (Unix.close_process_in p)
    );
    "uptime", (fun self _ dst -> self#say dst self#uptime);
    "help", (fun self _ dst -> self#say dst "please ask in private");
    "ping", (fun self _ dst -> self#say dst "pong");
    "on air[ ]*\\([a-z.]*\\)",
    (fun self orig dst ->
       self#say_metadata dst (List.hd (self#metadatas (Str.matched_group 1 orig)))
    );
    "alive",
    (fun self orig dst ->
       self#say dst (List.fold_left (fun s n -> s ^ (string_of_int n) ^ " ") "" (self#alive))
    );
    "version",
    (fun self _ dst -> self#say dst self#version);
    "",
    (fun self _ dst -> self#say dst "wtf?")
  ]

let _ =
  List.iter (fun (r, f) -> Bottle.add_public_message_handler (Str.regexp (Bottle.get_nick () ^ "[,:][ ]*" ^ r)) f) (List.rev pub_msg_handler)
