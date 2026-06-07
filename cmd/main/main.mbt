// Command-line tool for generating QR codes

fn main {
  println("=== MoonBit QR Code Generator ===\n")

  // Test 1: Simple text
  println("Generating QR code for: 'HELLO WORLD'")
  let qr1 = @lib.encode_low("HELLO WORLD")
  println("Version: " + qr1.version.to_string() + ", Size: " + qr1.size.to_string() + "x" + qr1.size.to_string())

  // Debug: print row 0 as binary
  print("Row 0: ")
  for x = 0; x < qr1.size; x = x + 1 {
    print(if qr1.modules[0][x] == 1 { "1" } else { "0" })
  }
  println("\n")

  println(qr1.to_string())

  // Test 2: Numeric data
  println("\nGenerating QR code for: '12345678'")
  let qr2 = @lib.encode_low("12345678")
  println("Version: " + qr2.version.to_string() + ", Size: " + qr2.size.to_string() + "x" + qr2.size.to_string())
  println(qr2.to_string())

  // Test 3: URL
  println("\nGenerating QR code for: 'https://moonbitlang.com'")
  let qr3 = @lib.encode_medium("https://moonbitlang.com")
  println("Version: " + qr3.version.to_string() + ", Size: " + qr3.size.to_string() + "x" + qr3.size.to_string())
  println(qr3.to_string())

  println("\n✅ QR Code generation successful!")
  println("Scan the QR codes above with your phone to test!")
}
