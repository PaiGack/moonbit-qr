package main

import (
	"fmt"
	"testing"

	"rsc.io/qr/coding"
)

// Test format encoding positions
func TestFormatEncoding(t *testing.T) {
	// Create a plan with Level L and Mask 3
	plan, err := coding.NewPlan(1, coding.L, 3)
	if err != nil {
		t.Fatal(err)
	}

	fmt.Println("\n=== Format Information Test ===")
	fmt.Println("Level: L, Mask: 3")

	fmt.Println("\nColumn 8 (vertical, rows 0-8, skip 6):")
	positions := []int{0, 1, 2, 3, 4, 5, 7, 8}
	for _, y := range positions {
		pix := plan.Pixel[y][8]
		black := (pix & coding.Black) != 0
		bit := 0
		if black {
			bit = 1
		}
		fmt.Printf("  pixel[%d][8] = %d\n", y, bit)
	}

	fmt.Println("\nRow 8 (horizontal, columns 0-8, skip 6):")
	for _, x := range positions {
		pix := plan.Pixel[8][x]
		black := (pix & coding.Black) != 0
		bit := 0
		if black {
			bit = 1
		}
		fmt.Printf("  pixel[8][%d] = %d\n", x, bit)
	}
}

// Test final QR code row 0
func TestRow0(t *testing.T) {
	plan, err := coding.NewPlan(1, coding.L, 3)
	if err != nil {
		t.Fatal(err)
	}

	// Encode "HELLO WORLD"
	text := coding.String("HELLO WORLD")
	code, err := plan.Encode(text)
	if err != nil {
		t.Fatal(err)
	}

	fmt.Println("\n=== Row 0 Test ===")
	fmt.Print("Go Row 0: ")
	for x := 0; x < code.Size; x++ {
		if code.Black(x, 0) {
			fmt.Print("1")
		} else {
			fmt.Print("0")
		}
	}
	fmt.Println()
}
