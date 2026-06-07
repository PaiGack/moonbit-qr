package main

import (
	"fmt"
	"rsc.io/qr"
)

func main() {
	// Generate QR for different masks to see the pattern
	for mask := 0; mask < 8; mask++ {
		// We need to generate with specific mask, but rsc.io/qr doesn't expose that
		// So we'll use the default and analyze format = 0x789D (mask 3)
		break
	}
	
	code, _ := qr.Encode("HELLO WORLD", qr.L)
	format := 0x789D
	
	fmt.Println("Reverse engineering format bit mapping:")
	fmt.Printf("Format = 0x%X =", format)
	for i := 14; i >= 0; i-- {
		bit := (format >> i) & 1
		fmt.Printf(" %d", bit)
	}
	fmt.Println()
	
	// Top-left horizontal (row 8, skipping column 6)
	fmt.Println("\nRow 8 (horizontal):")
	positions := []int{0, 1, 2, 3, 4, 5, 7, 8}
	for _, x := range positions {
		val := 0
		if code.Black(x, 8) { val = 1 }
		fmt.Printf("  pixel[8][%d] = %d\n", x, val)
	}
	
	// Top-left vertical (column 8, skipping row 6)
	fmt.Println("\nColumn 8 (vertical top):")
	vpositions := []int{0, 1, 2, 3, 4, 5, 7, 8}
	for _, y := range vpositions {
		val := 0
		if code.Black(8, y) { val = 1 }
		fmt.Printf("  pixel[%d][8] = %d\n", y, val)
	}
	
	// Try to match: which format bit corresponds to which pixel?
	fmt.Println("\nTrying to match Row 8 pixels to format bits...")
	row8_vals := []int{}
	for _, x := range positions {
		val := 0
		if code.Black(x, 8) { val = 1 }
		row8_vals = append(row8_vals, val)
	}
	fmt.Printf("Row 8 values: %v\n", row8_vals)
	
	// Try LSB first
	fmt.Print("Format bits 0-7: ")
	for i := 0; i < 8; i++ {
		fmt.Printf("%d ", (format>>i)&1)
	}
	fmt.Println()
}
