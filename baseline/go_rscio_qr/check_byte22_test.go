package main

import (
	"testing"
	"rsc.io/qr/coding"
)

func TestCheckByte22(t *testing.T) {
	p, _ := coding.NewPlan(coding.Version(1), coding.L, 0)
	_, err := p.Encode(coding.String("HELLO WORLD"))
	if err != nil {
		t.Fatal(err)
	}
	
	// Reconstruct byte 22 from pixels
	var byte22 byte = 0
	for bit := 0; bit < 8; bit++ {
		offset := uint(22*8 + bit)
		// Find pixel with this offset
		for y := 0; y < 21; y++ {
			for x := 0; x < 21; x++ {
				pixel := p.Pixel[y][x]
				if pixel.Offset() == offset {
					val := 0
					if pixel&coding.Black != 0 {
						byte22 |= (1 << (7 - bit))
						val = 1
					}
					t.Logf("  bit %d (offset %d) at (%d,%d): %d", bit, offset, x, y, val)
				}
			}
		}
	}
	
	t.Logf("\nReconstructed byte 22 = %d = 0b%08b", byte22, byte22)
	t.Logf("MoonBit byte 22 = 178 = 0b10110010")
}
