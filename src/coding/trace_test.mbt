test "trace first 20 bits written" {
  let plan = @coding.new_plan(1, @coding.L)
  @coding.init_grid(plan)

  let bits = @coding.encode_data("HELLO WORLD", 1, @coding.L)
  @coding.pad_bits(bits, 152)  // Version 1 Level L = 152 bits
  let data = @coding.add_error_correction(bits.bytes(), 7, 1)

  println("\n=== Tracing write to row 0, x=9-12 ===")
  println("Bytes around byte[17]:")
  for i = 15; i < 20 && i < data.length(); i = i + 1 {
    let byte = data[i]
    let mut line = "  byte[" + i.to_string() + "] = "
    for b = 7; b >= 0; b = b - 1 {
      line = line + (if (byte & (1 << b)) != 0 { "1" } else { "0" })
    }
    println(line)
  }

  // Write and observe
  @coding.write_data(plan, data)

  println("\nWritten to row 0, x=9-12 (before mask):")
  for x = 9; x <= 12; x = x + 1 {
    println("  pixel[0][" + x.to_string() + "] = " + plan.pixel[0][x].to_string())
  }

  // Compute what Go would have written
  println("\nExpected (Go) before mask: 1 1 1 0")
  println("Actual (MoonBit) before mask: " +
    plan.pixel[0][9].to_string() + " " +
    plan.pixel[0][10].to_string() + " " +
    plan.pixel[0][11].to_string() + " " +
    plan.pixel[0][12].to_string())
}
