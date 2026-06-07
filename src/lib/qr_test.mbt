// Tests for the lib package. Equivalence verified by comparing
// output against the Go reference (rsc.io/qr) via baseline/compare.sh.

///|
test "encode hello world (L)" {
  let qr = @lib.encode_low("HELLO WORLD")
  // Version 1: 21x21.
  assert_eq(qr.size, 21)
  // Top-left finder pattern: 7x7 block with black border and 3x3 inner.
  // pixel[0][0] is black.
  assert_eq(qr.is_black(0, 0), true)
  // pixel[0][6] is black (right side of finder).
  assert_eq(qr.is_black(6, 0), true)
  // pixel[1][1] is white (inside the outer ring).
  assert_eq(qr.is_black(1, 1), false)
  // pixel[3][3] is black (center of finder).
  assert_eq(qr.is_black(3, 3), true)
}

///|
test "encode numbers (L)" {
  let qr = @lib.encode_low("12345678")
  assert_eq(qr.size, 21)
  assert_eq(qr.is_black(0, 0), true)
}

///|
test "encode url (M)" {
  let qr = @lib.encode_medium("https://moonbitlang.com")
  // M + URL = version 2, 25x25
  assert_eq(qr.size, 25)
  assert_eq(qr.is_black(0, 0), true)
}

///|
test "to_string output format" {
  let qr = @lib.encode_low("HI")
  let s = qr.to_string()
  // Should have 21 lines for version 1.
  let lines : Array[StringView] = s.split("\n").collect()
  // The string ends with "\n" so we get an extra empty string.
  assert_eq(lines.length(), 22)
  // Each line should be 42 chars (21 pixels * 2 chars per pixel).
  assert_eq(lines[0].length(), 42)
}
