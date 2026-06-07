// QR code data encoding modes, ported from rsc.io/qr/coding/qr.go

///|
/// The minimum supported QR version.
pub let min_version : Int = 1

///|
/// The maximum supported QR version.
pub let max_version : Int = 40

///|
/// Version represents a QR version (1-40). Internally an Int.
pub type Version = Int

///|
/// A Level represents a QR error correction level.
pub enum Level {
  L // 7% redundant (least)
  M // 15% redundant
  Q // 25% redundant
  H // 30% redundant (most)
} derive(Eq, Compare)

///|
/// Convert Level to its integer index.
pub fn Level::to_int(self : Level) -> Int {
  match self {
    L => 0
    M => 1
    Q => 2
    H => 3
  }
}

///|
/// Convert integer to Level.
pub fn Level::of_int(i : Int) -> Level {
  match i {
    0 => L
    1 => M
    2 => Q
    3 => H
    _ => abort("invalid level")
  }
}

///|
/// Size class for character count indicators: 0 for v<=9, 1 for v<=26, 2 for v>26.
fn size_class(v : Version) -> Int {
  if v <= 9 {
    0
  } else if v <= 26 {
    1
  } else {
    2
  }
}

///|
/// The character set for alphanumeric encoding.
let alphabet : String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"

///|
/// Find index of character code unit cu in alphabet. Returns -1 if not found.
fn alpha_index(cu : Int) -> Int {
  for i = 0; i < alphabet.length(); i = i + 1 {
    if alphabet[i].to_int() == cu {
      return i
    }
  }
  -1
}

///|
/// An Encoding represents a data encoding mode for QR codes.
pub enum Encoding {
  /// Numeric mode (0-9 only)
  Num(String)
  /// Alphanumeric mode (0-9, A-Z, and a few symbols)
  Alpha(String)
  /// Byte/String mode (any UTF-8 data)
  Str(String)
}

///|
/// Create a Num encoding from a string (public constructor for cross-package use).
pub fn Encoding::num(s : String) -> Encoding {
  Encoding::Num(s)
}

///|
/// Create an Alpha encoding from a string (public constructor for cross-package use).
pub fn Encoding::alpha(s : String) -> Encoding {
  Encoding::Alpha(s)
}

///|
/// Create a Str encoding from a string (public constructor for cross-package use).
pub fn Encoding::str(s : String) -> Encoding {
  Encoding::Str(s)
}

///|
/// Check returns whether the encoding is valid for the given text.
pub fn Encoding::check(self : Encoding) -> Bool {
  match self {
    Num(s) => s_is_num(s)
    Alpha(s) => s_is_alpha(s)
    Str(_) => true
  }
}

///|
/// Bits returns the number of bits the encoding will produce.
pub fn Encoding::bits(self : Encoding, v : Version) -> Int {
  match self {
    Num(s) => num_bits(s.length(), v)
    Alpha(s) => alpha_bits(s.length(), v)
    Str(s) => string_bits(s.length(), v)
  }
}

///|
/// Encode writes the encoding's bits to b.
pub fn Encoding::encode(self : Encoding, b : Bits, v : Version) -> Unit {
  match self {
    Num(s) => num_encode(s, b, v)
    Alpha(s) => alpha_encode(s, b, v)
    Str(s) => string_encode(s, b, v)
  }
}

///|
/// Returns true if s consists only of decimal digits.
pub fn s_is_num(s : String) -> Bool {
  for i = 0; i < s.length(); i = i + 1 {
    let cu = s[i].to_int()
    if cu < '0' || cu > '9' {
      return false
    }
  }
  true
}

///|
/// Returns true if s consists only of alphanumeric characters in QR alphabet.
pub fn s_is_alpha(s : String) -> Bool {
  for i = 0; i < s.length(); i = i + 1 {
    if alpha_index(s[i].to_int()) < 0 {
      return false
    }
  }
  true
}

// Length-indicator sizes (in bits) per size class.

///|
let num_len : Array[Int] = [10, 12, 14]

///|
let alpha_len : Array[Int] = [9, 11, 13]

///|
let string_len : Array[Int] = [8, 16, 16]

///|
/// Compute the bit count for numeric encoding of a string of length n.
pub fn num_bits(n : Int, v : Version) -> Int {
  4 + num_len[size_class(v)] + (10 * n + 2) / 3
}

///|
/// Compute the bit count for alphanumeric encoding of a string of length n.
pub fn alpha_bits(n : Int, v : Version) -> Int {
  4 + alpha_len[size_class(v)] + (11 * n + 1) / 2
}

///|
/// Compute the bit count for byte encoding of a string of length n.
pub fn string_bits(n : Int, v : Version) -> Int {
  4 + string_len[size_class(v)] + 8 * n
}

///|
/// Write the numeric encoding of s into b.
pub fn num_encode(s : String, b : Bits, v : Version) -> Unit {
  b.write(1, 4)
  b.write(s.length(), num_len[size_class(v)])
  let len = s.length()
  let mut i = 0
  while i + 3 <= len {
    let c0 = s[i].to_int() - '0'.to_int()
    let c1 = s[i + 1].to_int() - '0'.to_int()
    let c2 = s[i + 2].to_int() - '0'.to_int()
    let w = c0 * 100 + c1 * 10 + c2
    b.write(w, 10)
    i = i + 3
  }
  let remaining = len - i
  if remaining == 1 {
    let c0 = s[i].to_int() - '0'.to_int()
    b.write(c0, 4)
  } else if remaining == 2 {
    let c0 = s[i].to_int() - '0'.to_int()
    let c1 = s[i + 1].to_int() - '0'.to_int()
    let w = c0 * 10 + c1
    b.write(w, 7)
  }
}

///|
/// Write the alphanumeric encoding of s into b.
pub fn alpha_encode(s : String, b : Bits, v : Version) -> Unit {
  b.write(2, 4)
  b.write(s.length(), alpha_len[size_class(v)])
  let len = s.length()
  let mut i = 0
  while i + 2 <= len {
    let c0 = alpha_index(s[i].to_int())
    let c1 = alpha_index(s[i + 1].to_int())
    let w = c0 * 45 + c1
    b.write(w, 11)
    i = i + 2
  }
  if i < len {
    b.write(alpha_index(s[i].to_int()), 6)
  }
}

///|
/// Write the byte (8-bit) encoding of s into b.
pub fn string_encode(s : String, b : Bits, v : Version) -> Unit {
  b.write(4, 4)
  b.write(s.length(), string_len[size_class(v)])
  for i = 0; i < s.length(); i = i + 1 {
    b.write(s[i].to_int(), 8)
  }
}
