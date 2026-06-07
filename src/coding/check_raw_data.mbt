test "check raw encoded data" {
  let bits = encode_data("HELLO WORLD", 1, L)
  pad_bits(bits, 152)

  let raw_bytes = bits.bytes()

  println("\nRaw data bytes (before error correction):")
  for i = 0; i < raw_bytes.length(); i = i + 1 {
    let byte_str = {
      let b = raw_bytes[i]
      let mut s = ""
      for bit = 7; bit >= 0; bit = bit - 1 {
        s = s + (if (b & (1 << bit)) != 0 { "1" } else { "0" })
      }
      s
    }
    println("  byte " + i.to_string() + " = " + raw_bytes[i].to_string() + " = 0b" + byte_str)
  }

  println("\nTotal bits: " + bits.bits().to_string())
}
