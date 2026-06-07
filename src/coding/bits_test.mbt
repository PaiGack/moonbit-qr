// Tests for Bits, ported from rsc.io/qr/coding (TestCheckGoRawData equivalent)
// We verify the equivalence by encoding HELLO WORLD as String mode (mode 4),
// padding to 152 bits, and comparing to the Go reference output.

///|
test "raw data bytes" {
  // Encode "HELLO WORLD" as String (mode=4) at version 1
  let bits = @coding.Bits::new()
  // Mode indicator: 4 (byte mode) = 0100
  bits.write(4, 4)
  // Length: 11 = 0x0B (for version 1, char count is 8 bits)
  bits.write(11, 8)
  // Bytes of "HELLO WORLD" = H, E, L, L, O, ' ', W, O, R, L, D
  for c in "HELLO WORLD" {
    bits.write(c.to_int(), 8)
  }
  // After 4 + 8 + 11*8 = 100 bits. Pad to 152 bits total.
  bits.pad(152)
  let data = bits.bytes()
  // Reference values from the Go test (TestCheckGoRawData):
  // 4 mode + 0x0B length = 0x40 0xB0
  // H=0x48, E=0x45, L=0x4C, L=0x4C, O=0x4F, ' '=0x20, W=0x57, O=0x4F
  // R=0x52, L=0x4C, D=0x44
  // Pad: 0xEC 0x11 ... etc.
  // Total 19 bytes.
  let expected = [b'\x40', b'\xb0', b'\x48', b'\x45', b'\x4c', b'\x4c',
                  b'\x4f', b'\x20', b'\x57', b'\x4f', b'\x52', b'\x4c',
                  b'\x44', b'\xec', b'\x11', b'\xec', b'\x11', b'\xec',
                  b'\x11']
  assert_eq(data.length(), expected.length())
  for i = 0; i < expected.length(); i = i + 1 {
    assert_eq(data[i], expected[i])
  }
}
