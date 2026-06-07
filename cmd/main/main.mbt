// Command-line tool for generating QR codes

fn main {
  println("=== MoonBit QR Code Generator ===\n")

  // Test 1: Simple text
  println("Generating QR code for: 'HELLO WORLD'")
  let qr1 = @lib.encode_low("HELLO WORLD")
  println("Version: " + qr1.version.to_string() + ", Size: " + qr1.size.to_string() + "x" + qr1.size.to_string())

  // Debug: print row 0 as binary
  let actual_bits : Array[Int] = []
  let mut row0 = "Row 0:    "
  for x = 0; x < qr1.size; x = x + 1 {
    let bit = qr1.modules[0][x]
    actual_bits.push(bit)
    row0 = row0 + (if bit == 1 { "1" } else { "0" })
  }
  println(row0)

  let expected_bits = [1,1,1,1,1,1,1,0,0,0,1,0,1,0,1,1,1,1,1,1,1]
  println("Expected: 111111100010101111111")

  // Print differences
  for x = 0; x < qr1.size; x = x + 1 {
    if actual_bits[x] != expected_bits[x] {
      println("  Diff at x=" + x.to_string() + ": got " + actual_bits[x].to_string() + ", expected " + expected_bits[x].to_string())
    }
  }

  // Check if positions 9-12 should be masked
  println("\nChecking mask pattern at row 0:")
  for x = 9; x <= 12; x = x + 1 {
    // Mask 3: (y + x) % 3 == 0
    let should_invert = (0 + x) % 3 == 0
    println("  x=" + x.to_string() + ": (0+" + x.to_string() + ")%3=" + ((0+x)%3).to_string() + ", should_invert=" + should_invert.to_string())
  }

  println("")

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
