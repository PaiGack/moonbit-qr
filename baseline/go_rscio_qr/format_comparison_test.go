package main

import (
	"testing"
	"rsc.io/qr"
)

func TestFormatInformation(t *testing.T) {
	qr1, err := qr.Encode("HELLO WORLD", qr.L)
	if err != nil {
		t.Fatal(err)
	}

	// Expected format info for Level L, Mask 0
	// According to QR spec

	t.Log("Row 8 (format info):")
	row8 := ""
	for x := 0; x < qr1.Size; x++ {
		if qr1.Black(x, 8) {
			row8 += "1"
		} else {
			row8 += "0"
		}
	}
	t.Log(row8)

	t.Log("Column 8 (format info):")
	col8 := ""
	for y := 0; y < qr1.Size; y++ {
		if qr1.Black(8, y) {
			col8 += "1"
		} else {
			col8 += "0"
		}
	}
	t.Log(col8)

	// Check specific positions that differ
	if qr1.Black(9, 1) {
		t.Error("Position (9,1) should be 0 but got 1")
	}

	if qr1.Black(8, 9) {
		t.Error("Position (8,9) in column 8 should be 0 but got 1")
	}

	if qr1.Black(8, 10) {
		t.Error("Position (8,10) in column 8 should be 0 but got 1")
	}
}
