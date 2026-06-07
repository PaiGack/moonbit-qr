test "trace first 20 bits written" {
  let plan = @coding.new_plan(1, @coding.L)
  @coding.init_grid(plan)

  let bits = @coding.encode_data("HELLO WORLD", 1, @coding.L)
  let data = @coding.add_error_correction(bits.bytes(), 7, 1)

  println("\n=== Tracing first 20 bits ===")
  println("First 3 bytes:")
  for i = 0; i < 3; i = i + 1 {
    let byte = data[i]
    let mut line = "  byte[" + i.to_string() + "] = "
    for b = 7; b >= 0; b = b - 1 {
      line = line + (if (byte & (1 << b)) != 0 { "1" } else { "0" })
    }
    println(line)
  }

  // Manually trace where first 20 bits should go
  // Based on Go's zigzag: start at (20,20), sweep DOWN
  println("\nExpected positions (Go order):")
  let positions = [
    (20, 20), (19, 20),  // first pair
    (20, 19), (19, 19),
    (20, 18), (19, 18),
    (20, 17), (19, 17),
    (20, 16), (19, 16),
    (20, 15), (19, 15),
    (20, 14), (19, 14),
    (20, 13), (19, 13),
    (20, 12), (19, 12),
    (20, 11), (19, 11)
  ]

  for i = 0; i < 20; i = i + 1 {
    let byte_idx = i / 8
    let bit_offset = 7 - (i % 8)
    let bit_val = if (data[byte_idx] & (1 << bit_offset)) != 0 { 1 } else { 0 }
    let pos = positions[i]
    println("  bit " + i.to_string() + " = " + bit_val.to_string() + " → (" + pos.0.to_string() + "," + pos.1.to_string() + ")")
  }

  // Now write and check row 0
  @coding.write_data(plan, data)
  println("\nActual row 0 (x=9-20):")
  let mut row_line = ""
  for x = 9; x <= 20; x = x + 1 {
    row_line = row_line + plan.pixel[0][x].to_string() + " "
  }
  println(row_line)
}
