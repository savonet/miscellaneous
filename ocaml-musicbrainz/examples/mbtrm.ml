open Musicbrainz

let () =
  let fname = Sys.argv.(1) in
  Printf.printf "file: %s\n%!" fname;
  let mp3 = Mad.openfile fname in
  let m = create () in
  let s = Trm.get_mp3_signature m fname (fun () -> Mad.decode_frame mp3) in
    Printf.printf "TRM: %s\n%!" (Trm.convert_sig_to_ascii (Trm.create ()) s);
    use_utf8 m true;
    set_max_items m 10;
    (* set_debug m true; *)
    set_depth m 2;
    query_with_args m Query.quick_track_info_from_track_id [s];
    let nartists = get_result_int m Query.get_num_artists in
      Printf.printf "Found %d artists.\n%!" nartists;
      for i = 0 to nartists - 1 do
        select m Query.S.rewind;
        select1 m Query.S.select_artist (i+1);
        let d = get_result_data m Query.artist_get_artist_name in
        let id = get_result_data m Query.artist_get_artist_id in
        let id = get_id_from_url m id in
          Printf.printf "Artist   : %s\n" d;
          Printf.printf "Artist ID: %s\n" id
      done;
      Mad.close mp3
