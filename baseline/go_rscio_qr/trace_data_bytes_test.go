package main

import (
	"testing"
	"rsc.io/qr/coding"
)

func TestTraceDataBytes(t *testing.T) {
	// Manually create the data with error correction
	text := coding.String("HELLO WORLD")
	bits := []byte{}
	
	// Mode: Alphanumeric (0010)
	// Length: 11 chars (9 bits for version 1)
	// Encode the data
	mode := byte(0b00100000) // 0010 followed by 4 bits of length
	bits = append(bits, mode)
	
	// This is getting complex, let's just use Encode and check the final data
	p, _ := coding.NewPlan(coding.Version(1), coding.L, 0)
	_, err := p.Encode(text)
	if err != nil {
		t.Fatal(err)
	}

	t.Log("\nLooking at pixels with specific offsets:")
	
	// Find pixels with offsets 176, 178, 180, 182
	targetOffsets := []uint{176, 178, 180, 182}
	for _, targetOffset := range targetOffsets {
		for y := 0; y < 21; y++ {
			for x := 0; x < 21; x++ {
				pixel := p.Pixel[y][x]
				if pixel.Offset() == targetOffset {
					val := 0
					if pixel&coding.Black != 0 {
						val = 1
					}
					byteIdx := targetOffset / 8
					bitOffset := 7 - (targetOffset % 8)
					t.Logf("  offset %d (byte %d bit %d) at (%d,%d): %d", targetOffset, byteIdx, bitOffset, x, y, val)
				}
			}
		}
	}
}
