test "data writing at row 0 positions 9-12" {
  // Test the data writing and masking for specific positions
  let plan = @coding.new_plan(1, @coding.L)
  @coding.init_grid(plan)

  // Encode data
  let bits = @coding.encode_data("HELLO WORLD", 1, @coding.L)
  let data_with_ec = @coding.add_error_correction(bits.bytes(), 7, 1)

  println("\n=== Encoded bytes ===")
  println("Total bytes: " + data_with_ec.length().to_string())
  for i = 0; i < 5 && i < data_with_ec.length(); i = i + 1 {
    let byte = data_with_ec[i]
    let mut binary = ""
    for b = 7; b >= 0; b = b - 1 {
      binary = binary + (if (byte & (1 << b)) != 0 { "1" } else { "0" })
    }
    let hex = if byte < 16 { "0" + byte.to_string() } else { byte.to_string() }
    println("  byte[" + i.to_string() + "] = " + byte.to_string() + " (0x" + hex + ") = " + binary)
  }

  // Go bytes for comparison:
  // byte[0] = 0x40 = 01000000
  // byte[1] = 0xB4 = 10110100
  // byte[2] = 0x84 = 10000100
  // byte[3] = 0x54 = 01010100
  // byte[4] = 0xC4 = 11000100

  // Write data (before mask)
  @coding.write_data(plan, data_with_ec)

  println("\nBefore mask (row 0, x=9-12):")
  for x = 9; x <= 12; x = x + 1 {
    println("  pixel[0][" + x.to_string() + "] = " + plan.pixel[0][x].to_string())
  }

  // Apply format
  @coding.write_format(plan, 3)

  // Apply mask
  @coding.apply_mask(plan, 3)

  println("\nAfter mask (row 0, x=9-12):")
  for x = 9; x <= 12; x = x + 1 {
    println("  pixel[0][" + x.to_string() + "] = " + plan.pixel[0][x].to_string())
  }

  println("\nMask pattern check:")
  for x = 9; x <= 12; x = x + 1 {
    let should_invert = (0 + x) % 3 == 0
    println("  x=" + x.to_string() + ": should_invert=" + should_invert.to_string())
  }
}
