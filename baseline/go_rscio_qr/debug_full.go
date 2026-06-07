package main

import (
	"fmt"
	"rsc.io/qr"
)

func main() {
	code, err := qr.Encode("HELLO WORLD", qr.L)
	if err != nil {
		panic(err)
	}

	fmt.Println("=== Go Implementation Debug ===")
	fmt.Printf("Text: HELLO WORLD\n")
	fmt.Printf("Size: %dx%d\n\n", code.Size, code.Size)

	// We can't access internal data directly, but we can see the pattern
	fmt.Println("Bitmap as binary (first 10 rows):")
	for y := 0; y < 10 && y < code.Size; y++ {
		fmt.Printf("Row %2d: ", y)
		for x := 0; x < code.Size; x++ {
			if code.Black(x, y) {
				fmt.Print("1")
			} else {
				fmt.Print("0")
			}
		}
		fmt.Println()
	}
}
