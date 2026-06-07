package main

import (
	"fmt"
	"rsc.io/qr"
)

func main() {
	// Test with "HELLO WORLD"
	code, err := qr.Encode("HELLO WORLD", qr.L)
	if err != nil {
		panic(err)
	}

	fmt.Println("=== Go Implementation Debug ===")
	fmt.Printf("Text: HELLO WORLD\n")
	fmt.Printf("Size: %dx%d\n", code.Size, code.Size)

	// Print first few rows of raw data (before mask)
	fmt.Println("\nFirst 3 rows of bitmap:")
	for y := 0; y < 3 && y < code.Size; y++ {
		for x := 0; x < code.Size; x++ {
			if code.Black(x, y) {
				fmt.Print("██")
			} else {
				fmt.Print("  ")
			}
		}
		fmt.Println()
	}

	// Print bitmap as hex bytes
	fmt.Println("\nBitmap as binary (first 10 rows):")
	for y := 0; y < 10 && y < code.Size; y++ {
		fmt.Printf("Row %2d: ", y)
		for x := 0; x < code.Size; x++ {
			if code.Black(x, y) {
				fmt.Print("1")
			} else {
				fmt.Print("0")
			}
		}
		fmt.Println()
	}
}
