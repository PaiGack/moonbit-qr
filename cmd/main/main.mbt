// Command-line tool for generating QR codes

fn main {
  println("=== Go QR Code Generator (Reference) ===")

  // Test 1: Simple text
  println("Generating QR code for: 'HELLO WORLD'")
  let qr1 = @lib.encode_low("HELLO WORLD")
  println("Size: " + qr1.size.to_string() + "x" + qr1.size.to_string())

  // Print row 0 as binary
  let mut row0 = "Row 0: "
  for x = 0; x < qr1.size; x = x + 1 {
    row0 = row0 + (if qr1.modules[0][x] == 1 { "1" } else { "0" })
  }
  println(row0)
  println(qr1.to_string())

  // Test 2: Numeric data
  println("\nGenerating QR code for: '12345678'")
  let qr2 = @lib.encode_low("12345678")
  println("Size: " + qr2.size.to_string() + "x" + qr2.size.to_string())
  println(qr2.to_string())

  // Test 3: URL
  println("\nGenerating QR code for: 'https://moonbitlang.com'")
  let qr3 = @lib.encode_medium("https://moonbitlang.com")
  println("Size: " + qr3.size.to_string() + "x" + qr3.size.to_string())
  println(qr3.to_string())

  println("\n✅ QR Code generation successful!")
  println("Scan the QR codes above with your phone to test!")
}
