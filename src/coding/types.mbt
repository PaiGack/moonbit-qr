// Core types for QR code encoding

// Level represents the error correction level
pub(all) enum Level {
  L  // Low: 7% error correction
  M  // Medium: 15% error correction
  Q  // Quartile: 25% error correction
  H  // High: 30% error correction
} derive(Eq, Debug)

// Version is QR code version (1-40), represented as Int
// Version determines the size: (V-1)*4 + 21 pixels per side

// Encoding mode for data
pub enum Encoding {
  Numeric      // 0-9
  Alphanumeric // 0-9, A-Z, space, $%*+-./:
  Byte         // arbitrary bytes
} derive(Eq, Debug)

// Pixel represents a single module in the QR code (0 or 1)

// PixelRole indicates the semantic meaning of a pixel
enum PixelRole {
  Data           // Data or error correction bits
  Check          // Format or version check bits
  Extra          // Timing, alignment, finder patterns
} derive(Eq, Debug)

// Bits is a buffer for building bit streams
pub struct Bits {
  mut b : Array[Int]      // byte buffer
  mut nbit : Int          // number of bits written
}

// new_bits creates a new Bits buffer
pub fn Bits::new() -> Bits {
  { b: Array::new(), nbit: 0 }
}

// reset clears the buffer
pub fn Bits::reset(self : Bits) -> Unit {
  self.b = Array::new()
  self.nbit = 0
}

// bits returns the number of bits written
pub fn Bits::bits(self : Bits) -> Int {
  self.nbit
}

// bytes returns the byte buffer (may have incomplete last byte)
pub fn Bits::bytes(self : Bits) -> Array[Int] {
  self.b
}

// append appends n bits from val (taking from low bits)
pub fn Bits::append(self : Bits, val : Int, n : Int) -> Unit {
  let mut v = val
  let mut remaining = n

  while remaining > 0 {
    let nbits = self.nbit % 8
    let space = 8 - nbits
    let take = if remaining < space { remaining } else { space }

    if nbits == 0 {
      self.b.push(0)
    }

    let idx = self.b.length() - 1
    let shift = space - take
    let mask = ((1 << take) - 1) << shift
    self.b[idx] = self.b[idx] | ((v << shift) & mask)

    v = v >> take
    self.nbit = self.nbit + take
    remaining = remaining - take
  }
}

// append_bytes adds entire bytes to the buffer
pub fn Bits::append_bytes(self : Bits, data : Array[Int]) -> Unit {
  for i = 0; i < data.length(); i = i + 1 {
    self.append(data[i], 8)
  }
}

// Plan holds the layout information for a QR code version
pub struct Plan {
  version : Int           // QR version (1-40)
  level : Level
  data_bytes : Int        // number of data bytes
  check_bytes : Int       // number of error correction bytes
  blocks : Int            // number of error correction blocks
  pixel : Array[Array[Int]]  // the pixel grid
  data_cache : Array[Int] // cache for encoded data
  num_pixels : Int        // total pixels in grid
}

// Version capacity table entry
struct VersionInfo {
  version : Int
  level_capacity : Array[Int]  // capacity in bytes for [L, M, Q, H]
  ec_codewords : Array[Int]    // error correction codewords per block for [L, M, Q, H]
  blocks : Array[Int]          // number of blocks for [L, M, Q, H]
}

// get_level_index converts Level to array index
fn level_index(level : Level) -> Int {
  match level {
    L => 0
    M => 1
    Q => 2
    H => 3
  }
}

// version_info returns capacity and layout info for a version
pub fn version_info(v : Int, level : Level) -> (Int, Int, Int) {
  let idx = level_index(level)

  // Simplified version table (we'll expand this later)
  // Returns: (data_capacity_bytes, ec_codewords_per_block, num_blocks)

  // Version 1
  if v == 1 {
    match level {
      L => (19, 7, 1)
      M => (16, 10, 1)
      Q => (13, 13, 1)
      H => (9, 17, 1)
    }
  } else if v == 2 {
    match level {
      L => (34, 10, 1)
      M => (28, 16, 1)
      Q => (22, 22, 1)
      H => (16, 28, 1)
    }
  } else if v == 3 {
    match level {
      L => (55, 15, 1)
      M => (44, 26, 1)
      Q => (34, 18, 2)
      H => (26, 22, 2)
    }
  } else if v == 4 {
    match level {
      L => (80, 20, 1)
      M => (64, 18, 2)
      Q => (48, 26, 2)
      H => (36, 16, 4)
    }
  } else if v == 5 {
    match level {
      L => (108, 26, 1)
      M => (86, 24, 2)
      Q => (62, 18, 4)
      H => (46, 22, 4)
    }
  } else {
    // For now, default to version 1 L for unsupported versions
    // TODO: Add full version table
    (19, 7, 1)
  }
}

// size returns the pixel dimension for a version
pub fn version_size(v : Int) -> Int {
  (v - 1) * 4 + 21
}
