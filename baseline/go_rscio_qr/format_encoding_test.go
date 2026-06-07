package main

import (
	"testing"
)

func TestFormatEncodingLevelLMask0(t *testing.T) {
	// Level L = 01, Mask 0 = 000
	// Data = 01 000 = 0x08
	data := 0x08

	// BCH(15,5) encoding
	gen := 0b10100110111
	d := data << 10

	for i := 0; i < 5; i++ {
		checkBit := 14 - i
		if (d & (1 << checkBit)) != 0 {
			shift := 4 - i
			d ^= (gen << shift)
		}
	}

	format := (data << 10) | d
	format ^= 0b101010000010010

	t.Logf("Format value: %d (0x%X)", format, format)

	// Print as binary
	formatBinary := ""
	for b := 14; b >= 0; b-- {
		if (format & (1 << b)) != 0 {
			formatBinary += "1"
		} else {
			formatBinary += "0"
		}
	}
	t.Logf("Format binary (15 bits): %s", formatBinary)

	// Now map these bits to the QR code positions
	t.Log("\nBit mapping (bit i -> positions):")
	for i := 0; i < 15; i++ {
		bitVal := "0"
		if (format & (1 << i)) != 0 {
			bitVal = "1"
		}

		// Top-left format info
		if i < 6 {
			t.Logf("  bit %d (%s): column 8, row %d", i, bitVal, i)
		} else if i < 8 {
			t.Logf("  bit %d (%s): column 8, row %d", i, bitVal, i+1)
		} else if i < 9 {
			t.Logf("  bit %d (%s): row 8, column 7", i, bitVal)
		} else {
			t.Logf("  bit %d (%s): row 8, column %d", i, bitVal, 14-i)
		}
	}
}
