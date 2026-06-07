package main

import "fmt"

// Replicate Go's format encoding
func encodeFormat(level int, mask int) int {
	// Level encoding: L=01, M=00, Q=11, H=10
	data := (level << 3) | (mask & 0x07)
	
	// BCH error correction
	d := data << 10
	gen := 0b10100110111
	
	for i := 0; i < 5; i++ {
		if (d & (1 << (14 - i))) != 0 {
			d ^= gen << (4 - i)
		}
	}
	
	format := (data << 10) | d
	format ^= 0b101010000010010
	
	return format
}

func main() {
	// L level = 01, mask = 3
	level := 0b01
	mask := 3
	
	format := encodeFormat(level, mask)
	fmt.Printf("Level=%02b, Mask=%d\n", level, mask)
	fmt.Printf("Format = 0x%X = 0b%015b\n", format, format)
	
	// Print each bit
	fmt.Println("\nFormat bits:")
	for i := 0; i < 15; i++ {
		bit := (format >> i) & 1
		fmt.Printf("  Bit %2d: %d\n", i, bit)
	}
}
