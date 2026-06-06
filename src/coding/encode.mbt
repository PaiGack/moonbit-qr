// Data encoding for QR codes

// encode_data encodes text data into a bit stream
pub fn encode_data(text : String, version : Int, level : Level) -> Bits {
  let bits = Bits::new()

  // Detect best encoding mode
  let mode = detect_mode(text)

  match mode {
    Numeric => encode_numeric(bits, text, version)
    Alphanumeric => encode_alphanumeric(bits, text, version)
    Byte => encode_bytes(bits, text, version)
  }

  bits
}

// detect_mode determines the best encoding mode for text
fn detect_mode(text : String) -> Encoding {
  let bytes = text.to_bytes()
  let mut all_numeric = true
  let mut all_alphanumeric = true

  for i = 0; i < bytes.length(); i = i + 1 {
    let c = bytes[i].to_int()

    // Check if numeric (0-9)
    if c < 48 || c > 57 {  // '0' = 48, '9' = 57
      all_numeric = false
    }

    // Check if alphanumeric (0-9, A-Z, space, $%*+-./:)
    if !is_alphanumeric(c) {
      all_alphanumeric = false
    }
  }

  if all_numeric {
    Numeric
  } else if all_alphanumeric {
    Alphanumeric
  } else {
    Byte
  }
}

// is_alphanumeric checks if a byte is in the alphanumeric character set
fn is_alphanumeric(c : Int) -> Bool {
  // 0-9
  if c >= 48 && c <= 57 {
    return true
  }
  // A-Z
  if c >= 65 && c <= 90 {
    return true
  }
  // space, $, %, *, +, -, ., /, :
  c == 32 || c == 36 || c == 37 || c == 42 || c == 43 ||
  c == 45 || c == 46 || c == 47 || c == 58
}

// encode_numeric encodes numeric data
fn encode_numeric(bits : Bits, text : String, version : Int) -> Unit {
  // Mode indicator for numeric: 0001
  bits.append(0b0001, 4)

  // Character count indicator
  let count_bits = if version <= 9 { 10 } else if version <= 26 { 12 } else { 14 }
  bits.append(text.length(), count_bits)

  // Encode data in groups of 3 digits
  let bytes = text.to_bytes()
  let mut i = 0

  while i < bytes.length() {
    let remaining = bytes.length() - i

    if remaining >= 3 {
      // 3 digits -> 10 bits
      let val = (bytes[i].to_int() - 48) * 100 + (bytes[i + 1].to_int() - 48) * 10 + (bytes[i + 2].to_int() - 48)
      bits.append(val, 10)
      i = i + 3
    } else if remaining == 2 {
      // 2 digits -> 7 bits
      let val = (bytes[i].to_int() - 48) * 10 + (bytes[i + 1].to_int() - 48)
      bits.append(val, 7)
      i = i + 2
    } else {
      // 1 digit -> 4 bits
      let val = bytes[i].to_int() - 48
      bits.append(val, 4)
      i = i + 1
    }
  }
}

// alphanumeric_value returns the encoding value for an alphanumeric character
fn alphanumeric_value(c : Int) -> Int {
  if c >= 48 && c <= 57 {
    return c - 48  // 0-9
  }
  if c >= 65 && c <= 90 {
    return c - 55  // A-Z (A=10, Z=35)
  }
  match c {
    32 => 36  // space
    36 => 37  // $
    37 => 38  // %
    42 => 39  // *
    43 => 40  // +
    45 => 41  // -
    46 => 42  // .
    47 => 43  // /
    58 => 44  // :
    _ => 0
  }
}

// encode_alphanumeric encodes alphanumeric data
fn encode_alphanumeric(bits : Bits, text : String, version : Int) -> Unit {
  // Mode indicator for alphanumeric: 0010
  bits.append(0b0010, 4)

  // Character count indicator
  let count_bits = if version <= 9 { 9 } else if version <= 26 { 11 } else { 13 }
  bits.append(text.length(), count_bits)

  // Encode data in pairs
  let bytes = text.to_bytes()
  let mut i = 0

  while i < bytes.length() {
    if i + 1 < bytes.length() {
      // 2 characters -> 11 bits
      let val1 = alphanumeric_value(bytes[i].to_int())
      let val2 = alphanumeric_value(bytes[i + 1].to_int())
      bits.append(val1 * 45 + val2, 11)
      i = i + 2
    } else {
      // 1 character -> 6 bits
      let val = alphanumeric_value(bytes[i].to_int())
      bits.append(val, 6)
      i = i + 1
    }
  }
}

// encode_bytes encodes byte data
fn encode_bytes(bits : Bits, text : String, _version : Int) -> Unit {
  // Mode indicator for byte: 0100
  bits.append(0b0100, 4)

  // Character count indicator
  let bytes = text.to_bytes()
  let count_bits = 8  // Simplified for version 1-9
  bits.append(bytes.length(), count_bits)

  // Encode each byte
  for i = 0; i < bytes.length(); i = i + 1 {
    bits.append(bytes[i].to_int(), 8)
  }
}

// pad_bits adds terminator and padding to reach target length
pub fn pad_bits(bits : Bits, target_bits : Int) -> Unit {
  // Add terminator (up to 4 zeros)
  let terminator_len = if target_bits - bits.bits() < 4 {
    target_bits - bits.bits()
  } else {
    4
  }
  bits.append(0, terminator_len)

  // Pad to byte boundary
  let remainder = bits.bits() % 8
  if remainder != 0 {
    bits.append(0, 8 - remainder)
  }

  // Add padding bytes (alternating 236, 17)
  let mut padding_byte = 236  // 0b11101100
  while bits.bits() < target_bits {
    bits.append(padding_byte, 8)
    padding_byte = if padding_byte == 236 { 17 } else { 236 }
  }
}

// add_error_correction adds Reed-Solomon error correction codes
pub fn add_error_correction(data : Array[Int], ec_per_block : Int, num_blocks : Int) -> Array[Int] {
  let data_per_block = data.length() / num_blocks
  let result = Array::new(capacity=data.length() + ec_per_block * num_blocks)

  // Generate error correction for each block
  let rs = @gf256.qr_rs(ec_per_block)
  let ec_blocks = Array::new(capacity=num_blocks)

  for block = 0; block < num_blocks; block = block + 1 {
    let start = block * data_per_block
    let end = start + data_per_block
    let block_data = Array::new(capacity=data_per_block)

    for i = start; i < end; i = i + 1 {
      block_data.push(data[i])
    }

    let ec = rs.ecc(block_data)
    ec_blocks.push(ec)
  }

  // Interleave data blocks
  for i = 0; i < data_per_block; i = i + 1 {
    for block = 0; block < num_blocks; block = block + 1 {
      let idx = block * data_per_block + i
      if idx < data.length() {
        result.push(data[idx])
      }
    }
  }

  // Interleave error correction blocks
  for i = 0; i < ec_per_block; i = i + 1 {
    for block = 0; block < num_blocks; block = block + 1 {
      if i < ec_blocks[block].length() {
        result.push(ec_blocks[block][i])
      }
    }
  }

  result
}

// write_data writes data bits into the QR code grid
pub fn write_data(p : Plan, data : Array[Int]) -> Unit {
  let size = p.pixel.length()
  let mut bit_idx = 0
  let total_bits = data.length() * 8

  // Write data in zigzag pattern (right to left, alternating up/down)
  let mut x = size - 1
  let mut going_up = true

  while x > 0 {
    // Skip timing column
    if x == 6 {
      x = x - 1
    }

    // Process two columns at a time
    for _col = 0; _col < 2; _col = _col + 1 {
      let col = x - _col

      let mut y = if going_up { size - 1 } else { 0 }

      while (going_up && y >= 0) || (!going_up && y < size) {
        if !is_function_pattern(p, col, y) {
          let bit = if bit_idx < total_bits {
            let byte_idx = bit_idx / 8
            let bit_offset = 7 - (bit_idx % 8)
            if (data[byte_idx] & (1 << bit_offset)) != 0 { pixel_on } else { pixel_off }
          } else {
            pixel_off
          }

          p.pixel[y][col] = bit
          bit_idx = bit_idx + 1
        }

        y = if going_up { y - 1 } else { y + 1 }
      }
    }

    x = x - 2
    going_up = !going_up
  }
}
