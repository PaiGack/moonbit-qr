package main

import (
	"testing"
	"rsc.io/qr/coding"
)

func TestCheckAllBytes(t *testing.T) {
	p, _ := coding.NewPlan(coding.Version(1), coding.L, 0)
	_, err := p.Encode(coding.String("HELLO WORLD"))
	if err != nil {
		t.Fatal(err)
	}
	
	t.Log("\nFirst 10 data+ec bytes:")
	for byteIdx := 0; byteIdx < 10; byteIdx++ {
		var byteVal byte = 0
		for bit := 0; bit < 8; bit++ {
			offset := uint(byteIdx*8 + bit)
			// Find pixel with this offset
			for y := 0; y < 21; y++ {
				for x := 0; x < 21; x++ {
					pixel := p.Pixel[y][x]
					if pixel.Offset() == offset {
						if pixel&coding.Black != 0 {
							byteVal |= (1 << (7 - bit))
						}
					}
				}
			}
		}
		t.Logf("  byte %d = %d = 0b%08b", byteIdx, byteVal, byteVal)
	}
}
