open Jack

let connect_re = Str.regexp "^c \\([0-9]+\\) \\([0-9]+\\)$"
let disconnect_re = Str.regexp "^d \\([0-9]+\\) \\([0-9]+\\)$"

let array_index a x =
  let ans = ref (-1) in
    Array.iteri (fun i y -> if x = y then ans := i) a;
    !ans

let () =
  let client =
    try
      Client.create "plumber"
    with
      | Client.Creation_error ->
        Printf.eprintf "Could not create a jack client. Is jackd running?\n%!";
        exit 1
  in
  let cmd = ref "" in
    while !cmd <> "q" && !cmd <> "quit" do
      Printf.printf "? %!";
      cmd := input_line stdin;
      let ports = Client.get_ports client in
      let is_input p = List.mem Port.Input (Port.flags (Client.port_by_name client p)) in
      let iports = Array.of_list (List.filter is_input ports) in
      let oports = Array.of_list (List.filter (fun p -> not (is_input p)) ports) in
      let cnx =
        List.concat
          (
            Array.to_list
              (
                Array.mapi
                  (fun i p ->
                     List.map
                       (fun p ->
                          i, array_index iports p
                       ) (Client.get_port_all_connections client (Client.port_by_name client p))
                  ) oports
              )
          )
      in
        match !cmd with
          | "h" | "help" ->
              Printf.printf "- c: connect\n- d: disconnect\n- l: list connections\n- p: list ports\n"
          | "p" | "ports" ->
              Printf.printf "- Output\n";
              Array.iteri (fun i s -> Printf.printf "  %d. %s\n" i s) oports;
              Printf.printf "- Input\n";
              Array.iteri (fun i s -> Printf.printf "  %d. %s\n" i s) iports
          | "l" ->
              List.iter (fun (i, j) -> Printf.printf "  %d -> %d\n" i j) cnx
          | "cpu" ->
              Printf.printf "Cpu load: %02.2f.\n" (Client.get_cpu_load client)
          | "md" ->
              Printf.printf "Max delayed: %02.2f.\n" (Stats.get_max_delayed client)
          | cmd when Str.string_match connect_re cmd 0 ->
              (
                try
                  let i = int_of_string (Str.matched_group 1 cmd) in
                  let j = int_of_string (Str.matched_group 2 cmd) in
                    Printf.printf "Connecting %s with %s.\n" (oports.(i)) (iports.(j));
                    Client.connect client (oports.(i)) (iports.(j))
                with
                  | Jack.Jack_error 17 ->
                      Printf.printf "Error: already connected.\n"
                  | Invalid_argument "index out of bounds" ->
                      Printf.printf "Error: unknown port.\n"
              )
          | cmd when Str.string_match disconnect_re cmd 0 ->
              (
                try
                  let i = int_of_string (Str.matched_group 1 cmd) in
                  let j = int_of_string (Str.matched_group 2 cmd) in
                    Printf.printf "Disconnecting %s with %s.\n" (oports.(i)) (iports.(j));
                    Client.disconnect client (oports.(i)) (iports.(j))
                with
                  | Jack.Jack_error (-1) ->
                      Printf.printf "Error: ports were not connected.\n"
                  | Invalid_argument "index out of bounds" ->
                      Printf.printf "Error: unknown port.\n"
              )
          | "q" | "quit" | "bye" ->
              Printf.printf "Bye!\n%!";
              exit 0
          | _ ->
              Printf.printf "Unknown command\n"
    done
