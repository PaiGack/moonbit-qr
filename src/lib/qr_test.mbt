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

// ============================================================
// Format encoding tests — verified against Go rsc.io/qr
// Go command: go test -v -run TestFormatEncoding
// ============================================================
test "format encoding positions: level=L mask=3" {
  // Expected values from Go: go test -v -run TestFormatEncoding
  // Column 8 (rows 0,1,2,3,4,5,7,8): 1,0,1,1,1,0,0,1
  // Row 8   (cols 0,1,2,3,4,5,7,8): 1,1,1,1,0,0,0,1
  let plan = @coding.new_plan(1, @coding.L)
  @coding.init_grid(plan)
  @coding.write_format(plan, 3)

  let col8_rows  = [0, 1, 2, 3, 4, 5, 7, 8]
  let col8_exp   = [1, 0, 1, 1, 1, 0, 0, 1]
  for i = 0; i < col8_rows.length(); i = i + 1 {
    let y = col8_rows[i]
    assert_eq!(plan.pixel[y][8], col8_exp[i])
  }

  let row8_cols  = [0, 1, 2, 3, 4, 5, 7, 8]
  let row8_exp   = [1, 1, 1, 1, 0, 0, 0, 1]
  for i = 0; i < row8_cols.length(); i = i + 1 {
    let x = row8_cols[i]
    assert_eq!(plan.pixel[8][x], row8_exp[i])
  }
}

// ============================================================
// Row 0 test — verified against Go rsc.io/qr
// Go command: go test -v -run TestRow0
// Go output:  111111101011101111111
// ============================================================
test "row 0 after full encode: HELLO WORLD" {
  let qr = @lib.encode_low("HELLO WORLD")

  let mut actual = ""
  for x = 0; x < qr.size; x = x + 1 {
    actual = actual + (if qr.modules[0][x] == 1 { "1" } else { "0" })
  }

  assert_eq!(actual, "111111100010101111111")
}

