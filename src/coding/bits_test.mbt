// Tests for Bits, ported from rsc.io/qr/coding (TestCheckGoRawData equivalent)
// We verify the equivalence by encoding HELLO WORLD as String mode (mode 4),
// padding, and comparing to the Go reference output.

///|
test "raw data bytes (Go reference: 31 bytes after Pad(152))" {
  // Encode "HELLO WORLD" as String (mode=4) at version 1
  let bits = @coding.Bits::new()
  bits.write(4, 4) // mode
  bits.write(11, 8) // length
  for c in "HELLO WORLD" {
    bits.write(c.to_int(), 8)
  }
  // The Go test calls bits.Pad(152) which pads the stream to 31 bytes
  // (matches the Go implementation, even though the comment says "152 bits").
  bits.pad(152)
  let data = bits.bytes()
  assert_eq(data.length(), 31)
}

///|
test "pad to 152 bits using delta" {
  // After encoding "HELLO WORLD" we have 100 bits.
  // To get to 152 bits (19 bytes), we need to add 52 bits.
  let bits = @coding.Bits::new()
  bits.write(4, 4)
  bits.write(11, 8)
  for c in "HELLO WORLD" {
    bits.write(c.to_int(), 8)
  }
  assert_eq(bits.bits(), 100)
  // Pad with delta = 52 (terminator 4 bits + 6 padding bytes)
  bits.pad(52)
  let data = bits.bytes()
  assert_eq(data.length(), 19)
  // Verify byte-by-byte equivalence with the Go output.
  // Layout: 4 mode (0100) + 8 length (00001011) + 11*8 chars = 100 bits.
  // Then terminator 0000 + 6 bytes EC 11 EC 11 EC 11.
  // Byte 0: 0100 0000 = 0x40 (mode + high 4 of length)
  // Byte 1: 1011 0100 = 0xB4 (low 4 of length + high 4 of 'H')
  // Byte 2: 1000 0100 = 0x84 (low 4 of 'H' + high 4 of 'E')
  // ...
  // Byte 11: 1100 0100 = 0xC4 (low 4 of 'L' + high 4 of 'D')
  // Byte 12: 0100 0000 = 0x40 (low 4 of 'D' in high nibble + terminator)
  // Bytes 13-18: 0xEC 0x11 0xEC 0x11 0xEC 0x11
  let expected = [
    b'\x40', b'\xb4', b'\x84', b'\x54', b'\xc4', b'\xc4', b'\xf2', b'\x05', b'\x74',
    b'\xf5', b'\x24', b'\xc4', b'\x40', b'\xec', b'\x11', b'\xec', b'\x11', b'\xec',
    b'\x11',
  ]
  for i = 0; i < expected.length(); i = i + 1 {
    assert_eq(data[i], expected[i])
  }
}
