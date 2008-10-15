open Iax

let _ = set_formats([Audio_format Gsm])
let _ = init(0)
let fd_iax = get_fd()
let iaxsession = session_new()

let _ = register iaxsession, "62.133.207.27","8100","mekker", 60

(*Printf.printf "%i\n%!" (100)
*)

let x = iaxsession,Lag_request 1234
let () = lag_request iaxsession

let _= while 1 > 0 do
	Printf.printf "Blaat\n%!";
        (*let _ = do_event x in*)
        begin
          try
            let e = get_event false in
              match e with
                | _,Lag_reply x -> Printf.printf "Got lag reply: lag = %i, jitter = %i\n" x.lag x.jitter
                | _ -> Printf.printf "Unknown event..\n"
          with
            | No_event -> Printf.printf "No event..\n";
        end;
	Unix.sleep 1;
done;;

