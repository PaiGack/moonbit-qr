// Simple test for QR code generation

test "Generate simple QR code" {
  let qr = @lib.encode_low("HELLO")

  // Check basic properties
  assert_true!(qr.size > 0)
  assert_true!(qr.version >= 1)

  // Verify size matches version
  let expected_size = (qr.version - 1) * 4 + 21
  assert_eq!(qr.size, expected_size)

  // Check that we have a valid grid
  assert_eq!(qr.modules.length(), qr.size)
}

test "Generate numeric QR code" {
  let qr = @lib.encode_low("12345")

  assert_true!(qr.size > 0)
  assert_eq!(qr.version, 1)  // Should fit in version 1
}

test "Different error correction levels" {
  let qr_l = @lib.encode_low("TEST")
  let qr_m = @lib.encode_medium("TEST")
  let qr_h = @lib.encode_high("TEST")

  // Higher error correction may need larger version
  assert_true!(qr_l.version <= qr_m.version)
  assert_true!(qr_m.version <= qr_h.version)
}

test "ASCII output generation" {
  let qr = @lib.encode_low("Hi")
  let output = qr.to_string()

  // Check that output is not empty
  assert_true!(output.length() > 0)

  // Output should contain block characters
  assert_true!(output.contains("█"))
}
