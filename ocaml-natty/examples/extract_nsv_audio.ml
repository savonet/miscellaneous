
let () =
  if Array.length Sys.argv <= 2 then
    failwith "usage: nsv input.nsv output.mp3";
  let filename = Sys.argv.(1) in
  let outfile = Sys.argv.(2) in
  let audio_f = open_out_bin outfile in
  let process f =
    let frames = ref 0 in
    try
      while true do
        let _,payload = Natty.Nsv.get_frame f in
        frames := !frames + 1;
        output_string audio_f payload.Natty.Nsv.audio
      done
    with
      | Not_found -> Printf.printf "Extracted %i frames.\n" !frames
  in
  let f = Natty.Nsv.open_f filename in
  Printf.printf "Got NSV file !\n";
  Printf.printf "Metadata: %s\n" f.Natty.Nsv.metadata;
  let audio_codec,video_codec = f.Natty.Nsv.format in
  let audio_format = 
    match audio_codec with
      | None -> "NONE"
      | Some Natty.Mp3 -> "MP3"
      | Some Natty.Audio_fourcc x -> x
      | _ -> "Unknown"
  in
  let video_format,params = 
    match video_codec with
      | Natty.Video_fourcc (x,params) -> x,params
      | _ -> assert false
  in
  Printf.printf "Audio codec: %s\n" audio_format;
  Printf.printf "Video codec: %s\n" video_format;
  begin
    match params with
      | None -> ()
      | Some params ->
          Printf.printf 
            "Width: %i, Height: %i\n" 
              params.Natty.width 
              params.Natty.height
  end ;
  if audio_codec = None then
    begin
      Printf.printf "Cannot extract audio: no audio track found..\n";
      raise Not_found
    end ;
  Printf.printf "Extracting audio to: %s...\n" outfile; 
  flush_all ();
  process f;
  Printf.printf "Done !\n";

