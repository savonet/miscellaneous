(**
  * An wav to AAC converter using ocaml-aac.
  *
  * @author Samuel Mimram
  *)

open Unix

let src = ref ""
let dst = ref ""

let buflen = ref 1024

let debug = true

let input_string chan len =
  let ans = String.create len in
    assert (input chan ans 0 len = len);
    ans

let input_int chan =
  let buf = input_string chan 4 in
    (int_of_char buf.[0])
    + (int_of_char buf.[1]) lsl 8
    + (int_of_char buf.[2]) lsl 16
    + (int_of_char buf.[3]) lsl 24

let input_short chan =
  let buf = input_string chan 2 in
    (int_of_char buf.[0]) + (int_of_char buf.[1]) lsl 8

let bitrate = ref 128000
let usage = "usage: wav2aac [options] source destination"

let _ =
  Arg.parse
    [
      "--bitrate", Arg.Int (fun b -> bitrate := b * 1000),
      "Bitrate, in bits per second, defaults to 128kbps" ;
    ]
    (
      let pnum = ref (-1) in
        (fun s -> incr pnum; match !pnum with
           | 0 -> src := s
           | 1 -> dst := s
           | _ -> Printf.eprintf "Error: too many arguments\n"; exit 1
        )
    ) usage;
  if !src = "" || !dst = "" then
    (
      Printf.printf "%s\n" usage;
      exit 1
    );
  let ic = open_in_bin !src in
  let oc = open_out_bin !dst in
    (* TODO: improve! *)
    if input_string ic 4 <> "RIFF" then invalid_arg "No RIFF tag";
    ignore (input_string ic 4);
    if input_string ic 4 <> "WAVE" then invalid_arg "No WAVE tag";
    if input_string ic 4 <> "fmt " then invalid_arg "No fmt tag";
    let _ = input_int ic in
    let _ = input_short ic in (* TODO: should be 1 *)
    let channels = input_short ic in
    let infreq = input_int ic in
    let _ = input_int ic in (* bytes / s *)
    let _ = input_short ic in (* block align *)
    let bits = input_short ic in
    let fos buf =
      let len = String.length buf / (2 * channels) in
      let ans = Array.init channels (fun _ -> Array.create len 0.) in
        for i = 0 to len - 1 do
          for c = 0 to channels - 1 do
            let n =
              int_of_char buf.[2 * channels * i + 2 * c]
              + int_of_char buf.[2 * channels * i + 2 * c + 1] lsl 8
            in
            let n =
              if n land 1 lsl 15 = 0 then
                n
              else
                (n land 0b111111111111111) - 32768
            in
              ans.(c).(i) <- float n /. 32768.;
              ans.(c).(i) <- max (-1.) (min 1. ans.(c).(i))
          done;
        done;
        ans
    in
    let enc, faac_samples, faac_buflen = Faac.create infreq channels in
    let outbuf = String.create faac_buflen in
    let encode buf =
      let fbuf = fos buf in
      let n = Faac.encode_ni enc fbuf 0 (Array.length fbuf.(0)) outbuf 0 in
        String.sub outbuf 0 n
    in
    let start = Unix.time () in
      (* TODO: use commandline parameters *)
      Faac.set_configuration enc ~mpeg_version:4 ~quality:100 ~bandwidth:16000 ();
      Printf.printf
        "Input detected: PCM WAVE %d channels, %d Hz, %d bits\n%!"
        channels infreq bits;
      if debug then
        Printf.printf
          "Encoding samples: %d, maximal returned buffer length: %d\n%!"
          faac_samples faac_buflen;
      Printf.printf
        "Encoding to: AAC %d channels, %d Hz, %d kbps\nPlease wait...\n%!"
        channels infreq (!bitrate/1000);
      if input_string ic 4 <> "data" then invalid_arg "No data tag";
      let buflen = faac_samples * 2 in
      let buf = String.create buflen in
        begin try while true do
          really_input ic buf 0 buflen;
          output_string oc (encode buf);
        done;
        with End_of_file -> () end;
        (* Flush the encoder. *)
        (
          let r = ref 42 in
            while !r > 0 do
              r := Faac.encode enc [||] 0 0 outbuf 0;
              output_string oc (String.sub outbuf 0 !r)
            done;
        );
        Faac.close enc;
        Printf.printf "Finished in %.0f seconds.\n" ((Unix.time ())-.start);
        Gc.full_major ()
