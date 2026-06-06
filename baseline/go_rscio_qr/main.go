package main

import (
	"fmt"
	"strings"

	"rsc.io/qr"
)

// Format QR code as terminal output using █ for black pixels
func formatQRCode(code *qr.Code) string {
	var sb strings.Builder
	size := code.Size

	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			if code.Black(x, y) {
				sb.WriteString("██")
			} else {
				sb.WriteString("  ")
			}
		}
		sb.WriteString("\n")
	}

	return sb.String()
}

func main() {
	fmt.Println("=== Go QR Code Generator (Reference) ===\n")

	// Test 1: Simple text with Low error correction
	fmt.Println("Generating QR code for: 'HELLO WORLD'")
	qr1, err := qr.Encode("HELLO WORLD", qr.L)
	if err != nil {
		panic(err)
	}
	fmt.Printf("Size: %dx%d\n", qr1.Size, qr1.Size)
	fmt.Println(formatQRCode(qr1))

	// Test 2: Numeric data with Low error correction
	fmt.Println("\nGenerating QR code for: '12345678'")
	qr2, err := qr.Encode("12345678", qr.L)
	if err != nil {
		panic(err)
	}
	fmt.Printf("Size: %dx%d\n", qr2.Size, qr2.Size)
	fmt.Println(formatQRCode(qr2))

	// Test 3: URL with Medium error correction
	fmt.Println("\nGenerating QR code for: 'https://moonbitlang.com'")
	qr3, err := qr.Encode("https://moonbitlang.com", qr.M)
	if err != nil {
		panic(err)
	}
	fmt.Printf("Size: %dx%d\n", qr3.Size, qr3.Size)
	fmt.Println(formatQRCode(qr3))

	fmt.Println("\n✅ QR Code generation successful!")
	fmt.Println("Scan the QR codes above with your phone to test!")
}
