test "detailed column 8 comparison" {
  let plan = @coding.new_plan(1, @coding.L)
  @coding.init_grid(plan)

  let bits = @coding.encode_data("HELLO WORLD", 1, @coding.L)
  @coding.pad_bits(bits, 152)
  let data = @coding.add_error_correction(bits.bytes(), 7, 1)

  @coding.write_data(plan, data)
  @coding.apply_mask(plan, 0)
  @coding.write_format(plan, 0)

  println("\nFull Column 8 (all 21 rows):")
  for y = 0; y < 21; y = y + 1 {
    let val = if plan.pixel[y][8] == 1 { "1" } else { "0" }
    println("  row " + y.to_string() + ": " + val)
  }

  let col8_str = {
    let mut s = ""
    for y = 0; y < 21; y = y + 1 {
      s = s + (if plan.pixel[y][8] == 1 { "1" } else { "0" })
    }
    s
  }
  println("\nColumn 8 as string: " + col8_str)
  println("Expected (Go):      001000111100011110111")
}
