(*****************************************************************************

  Liquidsoap, a programmable audio stream generator.
  Copyright 2003-2008 Savonet team

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details, fully stated in the COPYING
  file at the root of the liquidsoap distribution.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

 *****************************************************************************)

exception Unknown_format

type endianess = Big_endian | Little_endian
  and
     pcm_data = 
  { 
    channels        : int;
    sample_rate     : int;  
    bits_per_sample : int;
    endianess       : endianess
  }
  and
    video_params = 
  {
    width  : int;
    height : int
  } 
  and
     audio_codec = Pcm of pcm_data | Mp3 | Audio_fourcc of string | Unknown
  and
     video_codec = Video_fourcc of string*(video_params option) | Unknown

module Au = 
struct

  type t = 
    { data : Bitstring.bitstring ref;
      format      : audio_codec;
      length      : float option 
    }

  (* Check for Sun's au format.
   * Refs: http://ccrma.stanford.edu/courses/422/projects/NextFormat/ *)
  let open_f f = 
    let bits = Bitstring.bitstring_of_file f in
    bitmatch bits with
      | { ".snd"      : 4*8 : string;
          data_offset : 4*8 : bind (Int32.to_int data_offset);
          data_len    : 4*8 : bitstring;
          format      : 4*8 : bind (Int32.to_int format);
          sample_rate : 4*8 : bind (Int32.to_int sample_rate);
          channels    : 4*8 : bind (Int32.to_int channels);
          data        : -1  : bitstring,offset(data_offset*8)
        } -> let audio_codec = 
             (* Values from
              *   http://ccrma.stanford.edu/courses/422/projects/NextFormat/soundstruct.h *)
               let f x = 
                 Pcm { bits_per_sample = x; 
                       endianess       = Big_endian;
                       channels        = channels;
                       sample_rate     = sample_rate 
                     } 
               in
               match format with
                 | 2 -> f 8
                 | 3 -> f 16
                 | 4 -> f 24
                 | 5 -> f 32
                 | _ -> raise Unknown_format
             in
             let length = 
               let bytes_per_sample = 
                 match audio_codec with
                   | Pcm x -> (float_of_int x.bits_per_sample) /. 8.
                   | _ -> assert false
               in
                bitmatch data_len with
                 | { 0xff : 4;
                     0xff : 4;
                     0xff : 4;
                     0xff : 4 } 
                   -> None
                 | { x : 4*8 : bind (Int32.to_float x) } 
                   ->
                    Some 
                     (x /.
                     ((float_of_int sample_rate) *. 
                        bytes_per_sample))
             in   
             { data        = ref data;
               length      = length;
               format      = audio_codec 
             }
      | { _ } -> raise Unknown_format    
  
  let get_samples x n = 
    let ret,bits = 
      bitmatch !(x.data) with
        | { ret  : n*8 : string; 
            bits : -1  : bitstring } -> ret,bits
        | { _ } -> raise Not_found
    in
    x.data := bits;
    ret
  
  let get_all_samples x = 
    let ret = 
      Bitstring.string_of_bitstring !(x.data)
    in
    x.data := Bitstring.empty_bitstring;
    ret

end

module Wav = 
struct 

  type t =
    { data : Bitstring.bitstring ref;
      format      : audio_codec;
      length      : float option
    }
  
  let open_f f = 
    let bits = Bitstring.bitstring_of_file f in
    bitmatch bits with
      | {
         (* RIFF file magic *)
          "RIFF"          : 4*8 : string;
          chunk_size      : 4*8 : littleendian;
        (* Wave file magic *)
          "WAVE"          : 4*8 : string;
        (* fmt chunk magic *)
          "fmt "           : 4*8 : string; (* fmt chunk magic *)
        (* Size of chunk, here it's 16 for pcm *)
          fmt_chunk_size   : 4*8 : littleendian,
            check(Int32.to_int fmt_chunk_size = 16);
        (* Audio format, here 1 for pcm *)
          1               : 2*8 : littleendian;
          channels        : 2*8 : littleendian;
          sample_rate     : 4*8 : littleendian;
          byte_rate       : 4*8 : littleendian;
          block_align     : 2*8 : littleendian;
          bits_per_sample : 2*8 : littleendian;
          (* data chunk magic *)
          "data"          : 4*8 : string;
          data_chunk_size : 4*8 : littleendian;
          data            : -1  : bitstring 
        } -> 
          let format = 
          let f = Int32.to_int in
            Pcm { endianess       = Little_endian;
                  channels        = channels;
                  bits_per_sample = bits_per_sample;
                  sample_rate     = f sample_rate
                }
          in
          let length = 
            let f = Int32.to_float in
            let g = float_of_int in
              Some
                ((f data_chunk_size) /.
                  ((f sample_rate) *.
                  ((g bits_per_sample /. 8.))))
          in
          { data   = ref data;
            length = length;
            format = format 
          }
      | { _ } -> raise Unknown_format
  
  let get_samples x n =
    let ret,bits =
      bitmatch !(x.data) with
        | { ret  : n*8 : string;
            bits : -1  : bitstring } -> ret,bits
        | { _ } -> raise Not_found
    in
    x.data := bits;
    ret
  
  let get_all_samples x =
    let ret =
      Bitstring.string_of_bitstring !(x.data)
    in
    x.data := Bitstring.empty_bitstring;
    ret
  
end

module Aiff = 
struct

  exception Eof
  
  type compression = 
     { id   : string;
       name : string }
   and
       comm_data = 
     { num_chans       : int;
       num_frames      : int;
       bitspersample   : int; 
       samplerate      : float;
       compression     : compression option }
   and
       ssnd_data = 
    { comment : string;
      audio   : Bitstring.bitstring }
   and
       appl_data = 
    { signature : string;
      content   : string }
   and
      chunk = 
   | Comm of comm_data
   | Ssnd of ssnd_data
   | Fver of Int64.t
   | Form of string
   | Appl of appl_data
   | Auth of string
   | Name of string
   | Copyright of string
   | Anno of string
   | Inst of string
   | Mark of string
   | Skip of string
  
  type t =
    { ssnd     : Bitstring.bitstring ref;
      format   : audio_codec;
      length   : float option;
      chunks   : chunk list ref;
      rem_bits : Bitstring.bitstring ref
    }
  
  (* Ref: http://www.onicos.com/staff/iz/formats/ieee.c *)
  let float_of_ieee_extended bits = 
    bitmatch bits with
      | { v0 : 8;
          v1 : 8;
          v2 : 8;
          v3 : 8;
          v4 : 8;
          v5 : 8;
          v6 : 8;
          v7 : 8;
          v8 : 8;
          v9 : 8
        } -> 
          let expon = ((v0 land 0x7F) lsl 8) lor (v1 land 0xFF) in
          let hi_mant = 
            ((v2 land 0xFF) lsl 24) lor
            ((v3 land 0xFF) lsl 16) lor
            ((v4 land 0xFF) lsl 8) lor
             (v5 land 0xFF)
          in
          let lo_mant = 
            ((v6 land 0xFF) lsl 24) lor
            ((v7 land 0xFF) lsl 16) lor
            ((v8 land 0xFF) lsl 8) lor
             (v9 land 0xFF)
          in
          if (expon = 0) && (hi_mant = 0) && (lo_mant = 0) then
            0.
          else
            let f = 
              if expon = 0x7FFF then
                nan
              else
                let expon = expon - 16383 in
                let f = ldexp (float_of_int hi_mant) (expon-31) in
                f +. ldexp (float_of_int lo_mant) (expon-32)
            in
            if v0 = 0x80 then
              -.f
            else
              f
      | { _ } -> failwith "couldn't find enough data"
  
  let get_chunk_bits bits = 
    bitmatch bits with
         (* COMM chunk *)
      | { "COMM"        : 4*8  : string;
         (* COMM chunk size *)
          chunk_size    : 4*8;
          num_chans     : 2*8;
          num_frames    : 4*8;
          bitspersample : 2*8  : check (bitspersample < 33);
          samplerate    : 10*8 : bitstring;
          bits          : -1   : bitstring
        } -> 
           let bits,compression = 
             match Int32.to_int chunk_size with
               | 18  -> bits,None (* AIFF format *)
               | len -> 
                 bitmatch bits with
                   | { id   : 4*8          : string;
                       name : (len - 22)*8 : string;
                       bits : -1           : bitstring
                     } -> bits,Some {id = id; name = name }
                   | { _ } -> failwith "Error while parsing COMM chunk compression data.."
           in
           Comm { num_chans     = num_chans; 
                  num_frames    = Int32.to_int num_frames; 
                  bitspersample = bitspersample; 
                  samplerate    = float_of_ieee_extended samplerate;
                  compression   = compression },
           bits
         (* FVER chunk *)
      | { "FVER"     : 4*8 : string;
         (* Chunk size, here 4 bytes *)
          chunk_size : 4*8 : check (Int32.to_int chunk_size = 4); 
          v1         : 16;
          v2         : 16;
          bits       : -1  : bitstring
        } -> 
          let sversion = Printf.sprintf "0x%x%x" v1 v2 in
          let version = Int64.of_string sversion in
          if version <> Int64.of_string "0xa2805140" then
            begin
              failwith (Printf.sprintf "Unknown format version: %s" sversion);
            end ;
          Fver version, bits
         (* SSND chunk *)
      | { "SSND"       : 4*8 : string;
          chunk_size   : 4*8 : bind (Int32.to_int chunk_size);
          comment_size : 4*8 : bind (Int32.to_int comment_size);
         (* Block size, here 0 *)
          x            : 4*8 : check (Int32.to_int x = 0);
          comment      : comment_size*8     : string;
          audio        : (chunk_size - comment_size - 8)*8 : bitstring;
          bits         : -1 : bitstring
        } ->
          Ssnd { comment = comment; 
                 audio   = audio }, 
          bits
         (* APPL chunk *)
      | { "APPL"     : 4*8 : string;
          chunk_size : 4*8 : bind (Int32.to_int chunk_size);
          signature  : 4*8 : string;
          content    : (chunk_size - 4)*8 : string 
        } ->
          Appl  { signature = signature;
                  content   = content },
          bits
         (* ANNO/FORM/INST/MARK/SKIP chunk *)
      | { chunk_type : 4*8 : string;
          chunk_size : 4*8;
          data       : (Int32.to_int chunk_size)*8 : string;
          bits       : -1 : bitstring
        } ->
            let f bits = 
              bitmatch Bitstring.takebits 8 bits with
                | { 0 : 8 } -> Bitstring.dropbits 8 bits
                | { _ } -> bits
            in
            begin
              match chunk_type with
                | "FORM" -> Form data,bits
                | "INST" -> Inst data,bits
                | "MARK" -> Mark data,bits
                | "SKIP" -> Skip data,bits
                  (* All these chunks contains string,
                     chunk_size is usually the number 
                     of chars, we must drop one byte 
                     for the string ending byte if 
                     this is the case. *)
                | "ANNO" -> Anno data, f bits
                | "AUTH" -> Auth data, f bits
                | "[c] "
                | "(c) " -> Copyright data, f bits
                | "NAME" -> Name data, f bits
                | s -> 
                    failwith (Printf.sprintf "Unknown chunk: '%s'" s)
            end
      | { x : 4*8 : string } -> 
          failwith (Printf.sprintf "Couldn't parse chunk %s" x)
      | { _ : 0 : bitstring } -> raise Eof
      | { _ } -> failwith "couldn't parse chunk header" 
  
  let open_f f = 
    let bits = Bitstring.bitstring_of_file f in
    bitmatch bits with
      | {
          "FORM"          : 4*8 : string;
          chunk_size      : 4*8;
        (* AIFF file magic *)
          ("AIFF"|"AIFC") : 4*8 : string;
          bits            : -1  : bitstring
        } -> 
        (* Got a AIFF/AIFC header, now seeking for
         * at least COMM and SSND chunks *)
         let comm   = ref None in
         let ssnd   = ref None in
         let bits   = ref bits in
         let chunks = ref [] in
         begin
           try
             while !comm = None || !ssnd = None do
               let chunk,nbits = get_chunk_bits !bits in
               bits := nbits;
               match chunk with
                 | Comm x -> comm   := Some x
                 | Ssnd x -> ssnd   := Some x
                 | x      -> chunks := x :: !chunks
             done
           with
             | Eof -> 
                 failwith "End of file while seeking for COMM and SSND data"
         end;
         let get_some x = 
           match x with
             | Some x -> x
             | _      -> assert false
         in
         let comm = get_some !comm in
         let ssnd = get_some !ssnd in
         let format = 
           begin
             match comm.compression with
               | None -> ()
               | Some x -> 
                  match String.uppercase x.id with
                    | "NONE" -> ()
                    | _      -> 
                       failwith 
                         (Printf.sprintf 
                          "ocaml-natty doesn't support compressed data %s (%s)" 
                          x.id x.name)
           end ;
           Pcm { endianess       = Big_endian;
                 channels        = comm.num_chans;
                 bits_per_sample = comm.bitspersample;
                 sample_rate     = int_of_float (comm.samplerate)
               }
         in
         let length = 
           let f = float_of_int in
           Some ((f comm.num_frames) /. comm.samplerate)
         in
         { ssnd     = ref ssnd.audio;
           format   = format; 
           length   = length;
           chunks   = chunks;
           rem_bits = bits }      
      | { _ } -> raise Unknown_format
  
  let get_chunk x = 
    let chunk,nbits = get_chunk_bits !(x.rem_bits) in
    x.rem_bits := nbits;
    chunk

  let get_samples x n =
    let ret,bits =
      bitmatch !(x.ssnd) with
        | { ret  : n*8 : string;
            bits : -1  : bitstring } -> ret,bits
        | { _ } -> raise Not_found
    in
    x.ssnd := bits;
    ret
  
  let get_all_samples x =
    let ret =
      Bitstring.string_of_bitstring !(x.ssnd)
    in
    x.ssnd := Bitstring.empty_bitstring;
    ret

end

module Nsv = 
struct

  (* NSV parser written using ocaml-bitstring.
   *
   * Refs:
   *   http://ultravox.aol.com/NSVFormat.rtf
   *   http://www.multimedia.cx/nsv-format.txt
   *   http://www.nullsoft.com/nsv/samples/ *)
  
  type chunk = 
    { label   : string;
      content : string }
    and
       payload = 
    { audio  : string;
      video  : string;
      chunks : chunk list }
    and
       frame_header = 
      Sync of (audio_codec option)*video_codec
    | Async
    and
       frame = frame_header*payload
  
  type t = 
    { data     : Bitstring.bitstring ref;
      metadata : string;
      toc      : string;
      format   : (audio_codec option)*video_codec;
    }    
  
  let get_payload bits =
      let chunk_total_len = ref 0 in
      let chunks = ref [] in
      let get_chunk bits = 
        bitmatch bits with
          | { chunk_len  : 16 : littleendian,
                                check (chunk_len < 32768);
              chunk_type : 32 : string;
              chunk_data : chunk_len*8 : string;
              bits       : -1 : bitstring }
            -> chunk_total_len := !chunk_total_len + chunk_len + 2 + 4;
               let chunk = 
                 { label = chunk_type; 
                   content = chunk_data } 
               in
               chunks := chunk :: !chunks;
               bits
          | { _ } -> failwith "Error while getting chunk.."
      in
      (* The official spec is wrong at this place.
       * The correct spec for this header is:
       *
       * After the NSVs header are 5 bytes which provide the following length
       * information:
       *
       * v? vv vv aa aa
       * 
       * The lower nibble of byte 0 is num_chunk. The upper nibble of byte 0, along
       * with bytes 1 and 2 comprise the length of the video data in bytes. Since
       * there are 5 hex characters to describe the length, the maximum video
       * chunk size is 2^20 = 1 megabyte. Bytes 3-4 are the 16-bit length of the
       * audio chunk. Consider this example:
       *
       *  80 B7 00 D1 00
       *
       * The first 3 bytes, 80 B7 00, are rearranged in little endian form as
       * 0x00B780. Then the number is shifted right by 4 to give a video chunk
       * length of 0xB78 bytes. The audio chunk length bytes are D1 00, or 0x00D1
       * in little endian. *)
      bitmatch bits with
        | { vid_len1 : 4   : bitstring;
            num_aux  : 4;
            vid_len2 : 8   : bitstring;
            vid_len3 : 8   : bitstring;
            audio_len : 16 
                      : littleendian,
                        check (audio_len < 32768);
            bits : -1 : bitstring
          } ->
            begin
              let aux_plus_video_len = 
                BITSTRING {
                  vid_len3 : 8 : bitstring;
                  vid_len2 : 8 : bitstring;
                  vid_len1 : 4 : bitstring
                  }
              in
              let aux_plus_video_len = 
                bitmatch aux_plus_video_len with
                  | { len : 20 : bigendian,
                                 check(len < 524288 + num_aux*(32768+6))
                    } -> len
                  | { _ } -> assert false
              in
              let rec f i bits = 
                if i = num_aux then 
                  bits
                else
                  f (i+1) (get_chunk bits)
              in
              let bits = f 0 bits in
              bitmatch bits with
                | { video_data : (aux_plus_video_len - !chunk_total_len)*8 : string;
                    audio_data : audio_len*8 : string;
                    bits       : -1 : bitstring 
                  } -> { video  = video_data;
                         audio  = audio_data;
                         chunks = !chunks },
                       bits
                | { _ } -> failwith "error while getting frame data.."
            end
        | { _ } -> failwith "error while getting frame payload.."
  
  
  let get_frame_header bits =
    bitmatch bits with
      | { "NSVs" : 32 : string; (* Sync frame magic *)
          vidfmt : 32 : string;
          audfmt : 32 : string;
          width  : 16 : littleendian;
          height : 16 : littleendian;
          framerate_idx : 8 : littleendian;
          syncoffs      : 16;
          bits          : -1 : bitstring
        } -> 
          let audio_codec = 
            match audfmt with
              | "MP3 " -> Some Mp3
              | "NONE" -> None
              | x      -> Some (Audio_fourcc x)
          in
          let video_codec = 
            Video_fourcc (vidfmt, Some { width = width; height = height })
          in
          (Sync (audio_codec,video_codec)),bits
      | { 0xBEEF : 16 : littleendian; (* No sync frame magic *)
          bits : -1 : bitstring }
        -> Async,bits
      | { _ } -> raise Not_found
  
  let get_frame x = 
    let header,bits  = get_frame_header !(x.data) in
    let payload,bits = get_payload bits in
    x.data := bits;
    header,payload
  
  let open_f f =
    let bits = Bitstring.bitstring_of_file f in
    let g = Int32.to_int in
    bitmatch bits with
      | { "NSVf" : 4*8 : string; (* NSV magic *)
          header_size  : 4*8 : littleendian;
          file_size    : 4*8 : littleendian;
          file_len_ms  : 4*8 : littleendian;
          metadata_len : 4*8 : littleendian;
          toc_alloc    : 4*8 : littleendian;
          toc_size     : 4*8 : littleendian;
          metadata     : (g metadata_len)*8 : string;
          toc          : (g toc_alloc)*4*8  : string;
          bits         : -1  : bitstring
        } -> 
          let frame,_ = get_frame_header bits in
          let format = 
            match frame with
              | Sync (x,y) -> x,y
              | Async  -> failwith "error: file doesn't start with sync frame"
          in
          { data     = ref bits;
            metadata = metadata;
            toc      = toc;
            format   = format }
      | { _ } -> raise Unknown_format

end
