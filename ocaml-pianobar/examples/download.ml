
open Pianobar.Piano

open Http_client

type station = Default | Id of int

let user = ref ""
let password = ref ""

let station = ref Default
let format = ref (Mp3,"mp3")

let update_format x = 
  let ret = 
    match String.lowercase x with
      | "mp3" -> Mp3,"mp3"
      | "mp3_high" -> Mp3_high,"mp3"
      | "aac_plus" -> Aac_plus,"mp4"
      | _ -> failwith "Invalid format string."
  in
  format := ret

let usage = "download [options] username password"

let () =
  let speclist = 
    [
      "--station", Arg.Int (fun x -> station := Id x),
      "Id of the desired station (default: first known)." ;
      "--format", Arg.String update_format,
      "Audio format (one of: mp3, mp3_high, aac_plus)."
    ]
  in 
  Arg.parse speclist
    (
      let pnum = ref (-1) in
        (fun s -> incr pnum; match !pnum with
           | 0 -> user := s
           | 1 -> password := s
           | _ -> Printf.eprintf "Error: too many arguments\n"; exit 1
        )
    ) usage;
  if !user = "" || !password = "" then
    (
      Arg.usage speclist usage;
      exit 1
    );
  let user,password = !user,!password in
  let h = init () in
  login ~user ~password h ;
  let stations = get_stations h in
  let default_station () = 
    let print_station station = 
      Printf.printf "Got station '%s' with id '%d'\n" station.station_name station.station_id
     in
     List.iter print_station stations ;
     let station = List.hd stations in
     Printf.printf "Using station %s\n" station.station_name ;
     station
  in
  let rec find_station id l = 
    match l with
      | [] -> raise Not_found
      | x :: _ when x.station_id = id -> x
      | _ :: l -> find_station id l
  in
  let station = 
    match !station with
      | Default -> default_station ()
      | Id x -> 
       begin
         try
           find_station x stations
         with
           | Not_found -> 
               Printf.printf "Could not find a station with id: %d, \
                              using default." x ;
               default_station ()
       end
  in
  let format,fext = !format in
  let playlist = get_playlist ~format ~station h in
  let print_song song = 
    Printf.printf "Got song: '%s' by '%s'\n" song.title song.artist
  in
  List.iter print_song playlist ;
  let song = List.hd playlist in
  let filename = Printf.sprintf "%s - %s.%s" song.title song.artist fext in
  Printf.printf "Downloading '%s' by '%s' to '%s'\n" song.title song.artist filename;
  flush stdout ;
  let pipeline = new pipeline in
  let get_call = new get song.audio_url in
  get_call # set_response_body_storage (`File (fun () -> filename));
  pipeline # add get_call;
  pipeline # run()

let () = 
  Gc.full_major ()

