// Tests for GF(256) field arithmetic, ported from rsc.io/qr/gf256/gf256_test.go
// Compare with original Go tests for equivalence.

///|
fn bytes_eq(a : Array[Byte], b : Array[Byte]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i = 0; i < a.length(); i = i + 1 {
    if a[i] != b[i] {
      return false
    }
  }
  true
}

///|
test "basic exp" {
  let f = @gf256.Field::new(0x11d, 2)
  // f.Exp(0) == 1, f.Exp(1) == 2, f.Exp(255) == 1
  assert_eq(f.exp(0), b'\x01')
  assert_eq(f.exp(1), b'\x02')
  assert_eq(f.exp(255), b'\x01')
}

///|
test "ecc basic" {
  let f = @gf256.Field::new(0x11d, 2)
  let data = [b'\x10', b'\x20', b'\x0c', b'\x56', b'\x61', b'\x80',
              b'\xec', b'\x11', b'\xec', b'\x11', b'\xec', b'\x11',
              b'\xec', b'\x11', b'\xec', b'\x11']
  let want = [b'\xa5', b'\x24', b'\xd4', b'\xc1', b'\xed', b'\x36',
              b'\xc7', b'\x87', b'\x2c', b'\x55']
  let rs = @gf256.RSEncoder::new(f, want.length())
  let out = rs.ecc(data)
  assert_true(bytes_eq(out, want))
}

///|
test "ecc linear" {
  let f = @gf256.Field::new(0x11d, 2)
  let rs1 = @gf256.RSEncoder::new(f, 2)
  // 0 + 0 = 0
  let d1 : Array[Byte] = [b'\x00', b'\x00']
  let out1 = rs1.ecc(d1)
  assert_true(bytes_eq(out1, [b'\x00', b'\x00']))

  // Linear: ECC(d2) XOR ECC(d3) == ECC(d2 XOR d3)
  let d2 : Array[Byte] = [b'\x00', b'\x01']
  let c2 = rs1.ecc(d2)
  let d3 : Array[Byte] = [b'\x00', b'\x02']
  let c3 = rs1.ecc(d3)
  let cx : Array[Byte] = [c2[0] ^ c3[0], c2[1] ^ c3[1]]
  let d4 : Array[Byte] = [b'\x00', b'\x03']
  let c4 = rs1.ecc(d4)
  assert_true(bytes_eq(cx, c4))
}
