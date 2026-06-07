test "trace column 8 data writes" {
  let plan = new_plan(1, L)
  init_grid(plan)

  let bits = encode_data("HELLO WORLD", 1, L)
  pad_bits(bits, 152)
  let data = add_error_correction(bits.bytes(), 7, 1)

  println("\nData bytes (first 10 and byte 22):")
  for i = 0; i < 10 && i < data.length(); i = i + 1 {
    let byte_str = {
      let b = data[i]
      let mut s = ""
      for bit = 7; bit >= 0; bit = bit - 1 {
        s = s + (if (b & (1 << bit)) != 0 { "1" } else { "0" })
      }
      s
    }
    println("  byte " + i.to_string() + " = " + data[i].to_string() + " = 0b" + byte_str)
  }

  // Print byte 22 specifically
  if data.length() > 22 {
    let byte_str = {
      let b = data[22]
      let mut s = ""
      for bit = 7; bit >= 0; bit = bit - 1 {
        s = s + (if (b & (1 << bit)) != 0 { "1" } else { "0" })
      }
      s
    }
    println("  byte 22 = " + data[22].to_string() + " = 0b" + byte_str)
  }

  // Manually trace which bits go to column 8
  let size = 21
  let mut bit_idx = 0
  let mut x = size
  let col8_writes : Array[(Int, Int, Int)] = []  // (y, bit_idx, bit_value)

  while x > 0 {
    // UP sweep
    for y = size - 1; y >= 0; y = y - 1 {
      if !is_function_pattern(plan, x - 1, y) {
        if x - 1 == 8 {
          let byte_idx = bit_idx / 8
          let bit_offset = 7 - (bit_idx % 8)
          let bit_val = if byte_idx < data.length() && (data[byte_idx] & (1 << bit_offset)) != 0 { 1 } else { 0 }
          col8_writes.push((y, bit_idx, bit_val))
        }
        bit_idx = bit_idx + 1
      }

      if !is_function_pattern(plan, x - 2, y) {
        if x - 2 == 8 {
          let byte_idx = bit_idx / 8
          let bit_offset = 7 - (bit_idx % 8)
          let bit_val = if byte_idx < data.length() && (data[byte_idx] & (1 << bit_offset)) != 0 { 1 } else { 0 }
          col8_writes.push((y, bit_idx, bit_val))
        }
        bit_idx = bit_idx + 1
      }
    }

    x = x - 2
    if x == 7 { x = x - 1 }

    // DOWN sweep
    for y = 0; y < size; y = y + 1 {
      if !is_function_pattern(plan, x - 1, y) {
        if x - 1 == 8 {
          let byte_idx = bit_idx / 8
          let bit_offset = 7 - (bit_idx % 8)
          let bit_val = if byte_idx < data.length() && (data[byte_idx] & (1 << bit_offset)) != 0 { 1 } else { 0 }
          col8_writes.push((y, bit_idx, bit_val))
        }
        bit_idx = bit_idx + 1
      }

      if !is_function_pattern(plan, x - 2, y) {
        if x - 2 == 8 {
          let byte_idx = bit_idx / 8
          let bit_offset = 7 - (bit_idx % 8)
          let bit_val = if byte_idx < data.length() && (data[byte_idx] & (1 << bit_offset)) != 0 { 1 } else { 0 }
          col8_writes.push((y, bit_idx, bit_val))
        }
        bit_idx = bit_idx + 1
      }
    }

    x = x - 2
  }

  println("\nColumn 8 data writes (before mask):")
  for i = 0; i < col8_writes.length(); i = i + 1 {
    let (y, idx, val) = col8_writes[i]
    let byte_idx = idx / 8
    let bit_offset = 7 - (idx % 8)
    println("  (8," + y.to_string() + ") <- bit " + idx.to_string() + " (byte " + byte_idx.to_string() + " bit " + bit_offset.to_string() + ") = " + val.to_string())
  }
}
