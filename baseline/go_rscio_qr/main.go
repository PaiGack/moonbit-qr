package main

import (
	"fmt"
	"strings"

	"rsc.io/qr"
	"rsc.io/qr/coding"
)

// Test format encoding
func testFormatEncoding() {
	fmt.Println("=== Testing Format Encoding ===")

	// Create a plan with Level L and Mask 3
	plan, err := coding.NewPlan(1, coding.L, 3)
	if err != nil {
		panic(err)
	}

	fmt.Println("\nFormat information positions:")
	fmt.Println("Top-left area (row 0-8, column 8):")
	for y := 0; y <= 8; y++ {
		if y == 6 {
			continue // timing row
		}
		pix := plan.Pixel[y][8]
		black := (pix & coding.Black) != 0
		fmt.Printf("  pixel[%d][8] = %v\n", y, black)
	}

	fmt.Println("\nTop-left area (row 8, column 0-8):")
	for x := 0; x <= 8; x++ {
		if x == 6 {
			continue // timing column
		}
		pix := plan.Pixel[8][x]
		black := (pix & coding.Black) != 0
		fmt.Printf("  pixel[8][%d] = %v\n", x, black)
	}
}

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
	// Test format encoding first
	testFormatEncoding()
	fmt.Println()

	fmt.Println("=== Go QR Code Generator (Reference) ===")

	// Test 1: Simple text with Low error correction
	fmt.Println("Generating QR code for: 'HELLO WORLD'")
	qr1, err := qr.Encode("HELLO WORLD", qr.L)
	if err != nil {
		panic(err)
	}
	fmt.Printf("Size: %dx%d\n", qr1.Size, qr1.Size)

	// Print row 0 as binary
	fmt.Print("Row 0: ")
	for x := 0; x < qr1.Size; x++ {
		if qr1.Black(x, 0) {
			fmt.Print("1")
		} else {
			fmt.Print("0")
		}
	}
	fmt.Println()
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
