open Musicbrainz

let do_trm = ref true

let test_artist () =
  let m = create () in
    use_utf8 m true;
    set_max_items m 10;
    (* set_debug m true; *)
    set_depth m 2;
    query_with_args m Query.find_artist_by_name ["Halliday"];
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
      done

let test_trm () =
  let m = create () in
  let fd = Unix.openfile "/tmp/test.raw" [Unix.O_RDONLY] 0o400 in
  let buflen = 2048 in
  let buf = String.create buflen in
  let trm = TRM.create () in
  let s =
    TRM.get_signature ~trm 44100 2 16
      (fun () ->
         let r = Unix.read fd buf 0 buflen in
           String.sub buf 0 r
      )
  in
    Unix.close fd;
    Printf.printf "Signature: %s\n%!" (TRM.convert_sig_to_ascii trm s);
    use_utf8 m true;
    set_max_items m 10;
    (* set_debug m true; *)
    set_depth m 2;
    query_with_args m Query.track_info_from_TRM_id [TRM.convert_sig_to_ascii trm s];
    let ntracks = get_result_int m Query.get_num_tracks in
      Printf.printf "Found %d tracks.\n%!" ntracks;
      for i = 0 to ntracks - 1 do
        select m Query.S.rewind;
        select1 m Query.S.select_track (i+1);
        let d = get_result_data m Query.artist_get_artist_name in
        let id = get_result_data m Query.artist_get_artist_id in
        let id = get_id_from_url m id in
          Printf.printf "Artist   : %s\n" d;
          Printf.printf "Artist ID: %s\n" id
      done

let () =
  if !do_trm then
    test_trm ()
  else
    test_artist ()
