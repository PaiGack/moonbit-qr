package main

import (
	"fmt"
	"testing"

	"rsc.io/qr/coding"
)

// Test data before mask
func TestDataBeforeMask(t *testing.T) {
	// Encode "HELLO WORLD"
	text := coding.String("HELLO WORLD")

	// Get the bits
	var b coding.Bits
	text.Encode(&b, 1)
	b.AddCheckBytes(1, coding.L)
	bytes := b.Bytes()

	fmt.Println("\n=== Data Before Mask Test ===")
	fmt.Printf("Encoded bytes: %d bytes\n", len(bytes))
	for i := 0; i < len(bytes) && i < 5; i++ {
		fmt.Printf("  byte[%d] = 0x%02X = %08b\n", i, bytes[i], bytes[i])
	}

	// Now check what Go writes at row 0, positions 9-12
	// We need to understand the write_data zigzag pattern
	fmt.Println("\nRow 0, positions 9-12 in Go's pixel grid (before applying mask):")

	// Create a fresh plan with mask to see the final result
	plan2, _ := coding.NewPlan(1, coding.L, 3)
	code, _ := plan2.Encode(text)

	fmt.Print("Go Row 0 (final): ")
	for x := 0; x < 21; x++ {
		if code.Black(x, 0) {
			fmt.Print("1")
		} else {
			fmt.Print("0")
		}
	}
	fmt.Println()
}
