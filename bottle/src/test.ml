open Liq

let _ =
  let l = connect "localhost" 1234 in
    Printf.printf "%d\n%!" (List.hd (on_air l));
    List.iter (fun (a, b) -> Printf.printf "%s = %s\n%!" a b) (metadata l 1);
    List.iter
      (fun l ->
         Printf.printf "SONG:\n%!";
         List.iter
           (fun (a, b) ->
              Printf.printf "%s = %s\n%!" a b
           ) l
      ) (metadatas l "dolebrai.ogg");
    disconnect l
