
open Pianobar.Piano

open Http_client

let () = 
  let user = Sys.argv.(1) in
  let password = Sys.argv.(2) in
  let h = init () in
  login ~user ~password h ;
  let stations = get_stations h in
  let print_station station = 
    Printf.printf "Got station %s with id %d\n" station.station_name station.station_id
  in
  List.iter print_station stations ;
  let station = List.hd stations in
  Printf.printf "Using station %s\n" station.station_name ;
  let playlist = get_playlist ~format:Aac_plus ~station h in
  let print_song song = 
    Printf.printf "Got song: %s by %s\n" song.title song.artist
  in
  List.iter print_song playlist ;
  let song = List.hd playlist in
  let filename = Printf.sprintf "%s - %s.m4a" song.title song.artist in
  Printf.printf "Downloading %s by %s to %s\n" song.title song.artist filename;
  flush stdout ;
  let pipeline = new pipeline in
  let get_call = new get song.audio_url in
  get_call # set_response_body_storage (`File (fun () -> filename));
  pipeline # add get_call;
  pipeline # run()

let () = 
  Gc.full_major ()

