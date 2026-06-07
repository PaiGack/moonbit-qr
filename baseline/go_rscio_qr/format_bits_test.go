package main

import (
	"testing"
	"rsc.io/qr/coding"
)

func TestFormatBitsLevelLMask0(t *testing.T) {
	plan, err := coding.NewPlan(1, coding.L, 0)
	if err != nil {
		t.Fatal(err)
	}

	// Read format bits from the plan
	size := 21

	t.Log("Format info in Column 8 (rows 0-8 and 14-20):")
	col8Format := ""
	for y := 0; y <= 8; y++ {
		val := plan.Pixel[y][8]
		if val == coding.Black {
			col8Format += "1"
		} else {
			col8Format += "0"
		}
	}
	for y := 14; y < size; y++ {
		val := plan.Pixel[y][8]
		if val == coding.Black {
			col8Format += "1"
		} else {
			col8Format += "0"
		}
	}
	t.Logf("Column 8 format: %s", col8Format)

	t.Log("Format info in Row 8 (columns 0-8 and 13-20):")
	row8Format := ""
	for x := 0; x <= 8; x++ {
		val := plan.Pixel[8][x]
		if val == coding.Black {
			row8Format += "1"
		} else {
			row8Format += "0"
		}
	}
	for x := 13; x < size; x++ {
		val := plan.Pixel[8][x]
		if val == coding.Black {
			row8Format += "1"
		} else {
			row8Format += "0"
		}
	}
	t.Logf("Row 8 format: %s", row8Format)
}
