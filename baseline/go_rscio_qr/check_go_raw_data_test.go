package main

import (
	"testing"
	"rsc.io/qr/coding"
)

func TestCheckGoRawData(t *testing.T) {
	// Encode text
	text := coding.String("HELLO WORLD")
	bits := &coding.Bits{}
	text.Encode(bits, coding.Version(1))
	
	// Pad to 152 bits
	bits.Pad(152)
	
	data := bits.Bytes()
	
	t.Logf("\nRaw data bytes (after padding, before error correction):")
	t.Logf("Total bytes: %d", len(data))
	
	for i := 0; i < len(data); i++ {
		t.Logf("  byte %d = %d = 0b%08b", i, data[i], data[i])
	}
}
