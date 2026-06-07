// Pixel and Mask types for QR codes, ported from rsc.io/qr/coding/qr.go

///|
/// Pixel describes a single pixel in a QR code.
/// Packed as: bit 0 = Black, bit 1 = Invert, bits 2-5 = role, bits 6+ = offset.
pub type Pixel = Int

///|
/// Black indicates the pixel should be drawn black.
pub let black : Pixel = 1

///|
/// Invert indicates the pixel should be inverted when masked.
pub let invert : Pixel = 2

///|
/// PixelRole describes the role of a QR pixel.
pub enum PixelRole {
  /// No role (uninitialized pixel)
  None
  /// Position squares (large)
  Position
  /// Alignment squares (small)
  Alignment
  /// Timing strip between position squares
  Timing
  /// Format metadata
  Format
  /// Version pattern
  PVersion
  /// Unused pixel
  Unused
  /// Data bit
  Data
  /// Error correction check bit
  Check
  /// Extra (padding) bit
  Extra
} derive(Eq, Compare)

///|
/// Convert PixelRole to its integer index.
pub fn PixelRole::to_int(self : PixelRole) -> Int {
  match self {
    None => 0
    Position => 1
    Alignment => 2
    Timing => 3
    Format => 4
    PVersion => 5
    Unused => 6
    Data => 7
    Check => 8
    Extra => 9
  }
}

///|
/// Convert integer to PixelRole.
pub fn PixelRole::of_int(i : Int) -> PixelRole {
  match i {
    0 => None
    1 => Position
    2 => Alignment
    3 => Timing
    4 => Format
    5 => PVersion
    6 => Unused
    7 => Data
    8 => Check
    9 => Extra
    _ => abort("invalid pixel role")
  }
}

///|
/// Convert PixelRole to its Pixel value (the role bits in the packed pixel).
pub fn PixelRole::to_pixel(self : PixelRole) -> Pixel {
  self.to_int() << 2
}

///|
/// Extract the PixelRole from a packed Pixel value.
pub fn pixel_role(p : Pixel) -> PixelRole {
  PixelRole::of_int((p >> 2) & 15)
}

///|
/// Extract the offset from a packed Pixel value.
pub fn pixel_offset(p : Pixel) -> Int {
  p >> 6
}

///|
/// Build a Pixel value with a given offset (the high bits of the packed pixel).
pub fn offset_pixel(o : Int) -> Pixel {
  o << 6
}

///|
/// A Mask describes a mask applied to the QR code.
pub enum Mask {
  /// No mask.
  M0
  M1
  M2
  M3
  M4
  M5
  M6
  M7
} derive(Eq, Compare)

///|
/// Convert Mask to its integer index (0-7).
pub fn Mask::to_int(self : Mask) -> Int {
  match self {
    M0 => 0
    M1 => 1
    M2 => 2
    M3 => 3
    M4 => 4
    M5 => 5
    M6 => 6
    M7 => 7
  }
}

///|
/// Convert integer to Mask.
pub fn Mask::of_int(i : Int) -> Mask {
  match i {
    0 => M0
    1 => M1
    2 => M2
    3 => M3
    4 => M4
    5 => M5
    6 => M6
    7 => M7
    _ => abort("invalid mask")
  }
}

// Mask functions. The mask returns true if the pixel at (i, j) should be inverted.
fn mask_invert(m : Mask, i : Int, j : Int) -> Bool {
  match m {
    M0 => (i + j) % 2 == 0
    M1 => i % 2 == 0
    M2 => j % 3 == 0
    M3 => (i + j) % 3 == 0
    M4 => (i / 2 + j / 3) % 2 == 0
    M5 => (i * j) % 2 + (i * j) % 3 == 0
    M6 => ((i * j) % 2 + (i * j) % 3) % 2 == 0
    M7 => ((i * j) % 3 + (i + j) % 2) % 2 == 0
  }
}

///|
/// Invert returns true if the pixel at (y, x) should be inverted by the given mask.
pub fn Mask::invert(self : Mask, y : Int, x : Int) -> Bool {
  mask_invert(self, y, x)
}
