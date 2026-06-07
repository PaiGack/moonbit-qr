package main

import (
	"testing"
	"rsc.io/qr"
)

func TestColumn8Positions(t *testing.T) {
	qr1, _ := qr.Encode("HELLO WORLD", qr.L)
	size := qr1.Size

	t.Log("Column 8 values (should be format info, not masked):")
	for y := 0; y < size; y++ {
		val := 0
		if qr1.Black(8, y) {
			val = 1
		}
		// Check if mask would affect this position
		// Mask 0: (y + x) % 2 == 0
		maskPattern := (y + 8) % 2 == 0
		t.Logf("  y=%d: value=%d, mask0_would_invert=%v", y, val, maskPattern)
	}
}
