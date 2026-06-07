// Public QR code API, ported from rsc.io/qr/qr.go

///|
/// A Level denotes a QR error correction level.
/// From least to most tolerant of errors: L, M, Q, H.
pub enum LibLevel {
  /// 7% redundant
  L
  /// 15% redundant
  M
  /// 25% redundant
  Q
  /// 30% redundant
  H
} derive(Eq, Compare)

///|
/// QRCode represents the bitmap of a QR code.
pub struct QRCode {
  size : Int // pixels per side
  modules : Array[Array[Int]] // 2D array of 0/1 per pixel (1 = black, 0 = white)
}

///|
/// Return the size (pixels per side) of the QR code.
pub fn QRCode::size(self : QRCode) -> Int {
  self.size
}

///|
/// Return true if the pixel at (x, y) is black.
pub fn QRCode::is_black(self : QRCode, x : Int, y : Int) -> Bool {
  if x < 0 || x >= self.size || y < 0 || y >= self.size {
    return false
  }
  self.modules[y][x] == 1
}

///|
/// Format the QR code as an ASCII string with two spaces per pixel (▇▇ for black).
pub fn QRCode::to_string(self : QRCode) -> String {
  let sb = StringBuilder::new()
  for y = 0; y < self.size; y = y + 1 {
    for x = 0; x < self.size; x = x + 1 {
      if self.modules[y][x] == 1 {
        sb.write_string("██")
      } else {
        sb.write_string("  ")
      }
    }
    sb.write_string("\n")
  }
  sb.to_string()
}

///|
/// Convert a LibLevel to the internal coding::Level index.
fn lib_level_to_idx(l : LibLevel) -> Int {
  match l {
    L => 0
    M => 1
    Q => 2
    H => 3
  }
}

///|
/// Pick the smallest valid data encoding for the text.
fn pick_encoding(text : String) -> @coding.Encoding {
  if @coding.s_is_num(text) {
    @coding.Encoding::num(text)
  } else if @coding.s_is_alpha(text) {
    @coding.Encoding::alpha(text)
  } else {
    @coding.Encoding::str(text)
  }
}

///|
/// Encode text at the given error correction level and return a QR code bitmap.
pub fn encode(text : String, level : LibLevel) -> QRCode raise @coding.QRError {
  let enc = pick_encoding(text)
  let cl_idx = lib_level_to_idx(level)
  let cl = @coding.Level::of_int(cl_idx)
  // Pick the smallest version that fits.
  let mut v = @coding.min_version
  while v <= @coding.max_version {
    if enc.bits(v) <= @coding.version_data_bytes(v, cl) * 8 {
      break
    }
    v = v + 1
  }
  if v > @coding.max_version {
    raise @coding.QRError::new("text too long to encode as QR")
  }
  // Build the plan and encode.
  let p = @coding.Plan::new(v, cl, @coding.Mask::of_int(0))
  let code = p.encode([enc])
  // Convert the code's bitmap to a 2D array of 0/1.
  let modules : Array[Array[Int]] = Array::make(code.size, Array::new())
  for y = 0; y < code.size; y = y + 1 {
    let row : Array[Int] = Array::make(code.size, 0)
    for x = 0; x < code.size; x = x + 1 {
      if code.black(x, y) {
        row[x] = 1
      }
    }
    modules[y] = row
  }
  { size: code.size, modules }
}

///|
/// Encode text at error correction level L (7% redundant).
/// Aborts the program if encoding fails (e.g., text too long).
pub fn encode_low(text : String) -> QRCode {
  encode(text, L) catch {
    @coding.QRError::QRError(msg) => abort("qr encoding failed: " + msg)
  }
}

///|
/// Encode text at error correction level M (15% redundant).
/// Aborts the program if encoding fails.
pub fn encode_medium(text : String) -> QRCode {
  encode(text, M) catch {
    @coding.QRError::QRError(msg) => abort("qr encoding failed: " + msg)
  }
}

///|
/// Encode text at error correction level Q (25% redundant).
/// Aborts the program if encoding fails.
pub fn encode_high(text : String) -> QRCode {
  encode(text, Q) catch {
    @coding.QRError::QRError(msg) => abort("qr encoding failed: " + msg)
  }
}
