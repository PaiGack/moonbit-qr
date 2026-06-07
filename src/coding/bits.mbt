// Bit buffer for QR code data encoding, ported from rsc.io/qr/coding/qr.go

///|
/// Bits holds a sequence of bits, packed MSB-first into bytes.
pub struct Bits {
  b : Array[Byte]
  mut nbit : Int
}

///|
/// Create a new empty Bits buffer.
pub fn Bits::new() -> Bits {
  { b: Array::new(), nbit: 0 }
}

///|
/// Reset the buffer to empty (preserves underlying capacity).
pub fn Bits::reset(self : Bits) -> Unit {
  self.b.clear()
  self.nbit = 0
}

///|
/// Return the number of bits written so far.
pub fn Bits::bits(self : Bits) -> Int {
  self.nbit
}

///|
/// Return the underlying byte slice. Aborts if nbit is not a multiple of 8.
pub fn Bits::bytes(self : Bits) -> Array[Byte] {
  if self.nbit % 8 != 0 {
    abort("qr: fractional byte")
  }
  self.b
}

///|
/// Append the given byte slice. Aborts if nbit is not a multiple of 8.
pub fn Bits::append(self : Bits, p : Array[Byte]) -> Unit {
  if self.nbit % 8 != 0 {
    abort("qr: fractional byte")
  }
  for i = 0; i < p.length(); i = i + 1 {
    self.b.push(p[i])
  }
  self.nbit = self.nbit + 8 * p.length()
}

///|
/// Write v (nbit bits long) to the buffer, MSB first.
pub fn Bits::write(self : Bits, v_in : Int, nbit_in : Int) -> Unit {
  let mut v = v_in
  let mut nbit = nbit_in
  while nbit > 0 {
    let mut n = nbit
    if n > 8 {
      n = 8
    }
    let pos_before = self.nbit % 8
    if pos_before == 0 {
      // Starting a new byte.
      self.b.push(b'\x00')
    } else {
      // Cap n to fill the rest of the current byte.
      let m = 8 - pos_before
      if n > m {
        n = m
      }
    }
    self.nbit = self.nbit + n
    let sh = nbit - n
    let byte_idx = self.b.length() - 1
    let cur = self.b[byte_idx].to_int()
    // bits_to_write: the n MSB-aligned bits of v
    let bits_to_write = (v >> sh) & ((1 << n) - 1)
    // Place bits at position (8 - n - pos_before)
    let shift = 8 - n - pos_before
    let mask = bits_to_write << shift
    self.b[byte_idx] = (cur | mask).to_byte()
    // clear the bits we just wrote from v
    v = v & ((1 << sh) - 1)
    nbit = nbit - n
  }
}

///|
/// Pad the bit stream to length n with the QR-code padding pattern
/// (0xEC, 0x11 repeating).
pub fn Bits::pad(self : Bits, n : Int) -> Unit {
  if n < 0 {
    abort("qr: invalid pad size")
  }
  if n <= 4 {
    self.write(0, n)
  } else {
    self.write(0, 4)
    let mut rem = n - 4
    let align_bits = if self.nbit % 8 == 0 { 0 } else { 8 - (self.nbit % 8) }
    rem = rem - align_bits
    self.write(0, align_bits)
    let pad = rem / 8
    for i = 0; i < pad; i = i + 2 {
      self.write(0xec, 8)
      if i + 1 >= pad {
        break
      }
      self.write(0x11, 8)
    }
  }
}
