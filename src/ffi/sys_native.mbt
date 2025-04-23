///|
fn mbt_string_to_utf8_bytes(str : String, is_filename : Bool) -> Bytes {
  let res : Array[Byte] = []
  let len = str.length()
  let mut i = 0
  while i < len {
    let mut c = str[i].to_int()
    if 0xD800 <= c && c <= 0xDBFF {
      c -= 0xD800
      i = i + 1
      let l = str[i].to_int() - 0xDC00
      c = (c << 10) + l + 0x10000
    }

    // stdout accepts UTF-8, so convert the stream to UTF-8 first
    if c < 0x80 {
      res.push(c.to_byte())
    } else if c < 0x800 {
      res.push((0xc0 + (c >> 6)).to_byte())
      res.push((0x80 + (c & 0x3f)).to_byte())
    } else if c < 0x10000 {
      res.push((0xe0 + (c >> 12)).to_byte())
      res.push((0x80 + ((c >> 6) & 0x3f)).to_byte())
      res.push((0x80 + (c & 0x3f)).to_byte())
    } else {
      res.push((0xf0 + (c >> 18)).to_byte())
      res.push((0x80 + ((c >> 12) & 0x3f)).to_byte())
      res.push((0x80 + ((c >> 6) & 0x3f)).to_byte())
      res.push((0x80 + (c & 0x3f)).to_byte())
    }
    i = i + 1
  }
  if is_filename {
    res.push((0).to_byte())
  }
  Bytes::from_array(res)
}

extern "C" fn preprocess_ffi(cfilename:Bytes,preprocessed_filename:Bytes)->Int = "preprocess"
extern "C" fn fasm_ffi(asm_filename:Bytes)->Int = "fasm"

pub fn preprocess(cfilename:String,preprocessed_filename:String)->Unit{
  let _status = preprocess_ffi(mbt_string_to_utf8_bytes(cfilename,true),mbt_string_to_utf8_bytes(preprocessed_filename,true))
  if _status != 0{
    panic()
  }
}
pub fn fasm(asm_filename:String)->Unit{
  let _status = fasm_ffi(mbt_string_to_utf8_bytes(asm_filename,true))
    if _status != 0{
    panic()
  }
}

///|
// extern "C"  fn run_cmd_ffi(cmd : Bytes) -> Int = "run_cmd"

///|
/// 
// pub fn run_cmd(cmd : String) -> Unit {
//   let _status = run_cmd_ffi(mbt_string_to_utf8_bytes(cmd, true))
//   // if status != 0 {
//   //   panic()
//   // }
// }
