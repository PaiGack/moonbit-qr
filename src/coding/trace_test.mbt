test "trace data write positions" {
  let plan = @coding.new_plan(1, @coding.L)
  @coding.init_grid(plan)

  // Create dummy data: 0x00, 0x01, 0x02, 0x03, ...
  let data = Array::make(26, 0)
  for i = 0; i < 26; i = i + 1 {
    data[i] = i
  }

  // Manually trace where bits go (simplified version of write_data)
  let size = 21
  let mut bit_idx = 0
  let mut x = size

  println("First 150 bits written to:")

  while x > 0 && bit_idx < 150 {
    // UP sweep
    for y = size - 1; y >= 0 && bit_idx < 150; y = y - 1 {
      if !@coding.is_function_pattern(plan, x - 1, y) {
        println("  bit " + bit_idx.to_string() + " -> (" + (x-1).to_string() + "," + y.to_string() + ")")
        bit_idx = bit_idx + 1
      }

      if bit_idx < 150 && !@coding.is_function_pattern(plan, x - 2, y) {
        println("  bit " + bit_idx.to_string() + " -> (" + (x-2).to_string() + "," + y.to_string() + ")")
        bit_idx = bit_idx + 1
      }
    }

    x = x - 2
    if x == 7 { x = x - 1 }

    // DOWN sweep
    for y = 0; y < size && bit_idx < 150; y = y + 1 {
      if bit_idx < 150 && !@coding.is_function_pattern(plan, x - 1, y) {
        println("  bit " + bit_idx.to_string() + " -> (" + (x-1).to_string() + "," + y.to_string() + ")")
        bit_idx = bit_idx + 1
      }

      if bit_idx < 150 && !@coding.is_function_pattern(plan, x - 2, y) {
        println("  bit " + bit_idx.to_string() + " -> (" + (x-2).to_string() + "," + y.to_string() + ")")
        bit_idx = bit_idx + 1
      }
    }

    x = x - 2
  }
}
