package main

import (
	"testing"
	"rsc.io/qr/coding"
)

func TestTraceColumn8(t *testing.T) {
	p, _ := coding.NewPlan(coding.Version(1), coding.L, 0)
	_, err := p.Encode(coding.String("HELLO WORLD"))
	if err != nil {
		t.Fatal(err)
	}

	// Print column 8, rows 9-12 after encode
	t.Log("\nColumn 8 final values (after mask):")
	for y := 9; y <= 12; y++ {
		pixel := p.Pixel[y][8]
		val := 0
		if pixel&coding.Black != 0 {
			val = 1
		}
		t.Logf("  row %d: %d (offset=%d)", y, val, pixel.Offset())
	}
}
