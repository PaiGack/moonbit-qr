package main

import (
	"fmt"
	"rsc.io/qr"
)

func main() {
	code, _ := qr.Encode("HELLO WORLD", qr.L)
	
	format := 0x789D
	fmt.Printf("Format = 0x%X = 0b%015b\n\n", format, format)
	
	// Print format bits
	fmt.Println("Format bits:")
	for i := 0; i < 15; i++ {
		bit := (format >> i) & 1
		fmt.Printf("  bit %2d = %d\n", i, bit)
	}
	
	// Print actual QR code pixels in format area
	fmt.Println("\nActual QR pixels:")
	fmt.Println("Column 8, rows 0-5:")
	for y := 0; y <= 5; y++ {
		val := 0
		if code.Black(8, y) { val = 1 }
		fmt.Printf("  pixel[%d][8] = %d\n", y, val)
	}
	
	fmt.Println("\nRow 8, columns 0-8:")
	for x := 0; x <= 8; x++ {
		val := 0
		if code.Black(x, 8) { val = 1 }
		fmt.Printf("  pixel[8][%d] = %d\n", x, val)
	}
}
