package main

import (
	"fmt"
	"rsc.io/qr/coding"
)

func main() {
	fmt.Println("=== Testing all masks for HELLO WORLD ===")

	// Encode "HELLO WORLD" as String (byte mode)
	text := "HELLO WORLD"
	enc := coding.String(text)

	for mask := 0; mask < 8; mask++ {
		// Create plan with mask
		plan, err := coding.NewPlan(1, coding.L, coding.Mask(mask))
		if err != nil {
			panic(err)
		}

		// Encode
		code, err := plan.Encode(enc)
		if err != nil {
			panic(err)
		}

		// Print row 0
		fmt.Printf("Mask %d - Row 0: ", mask)
		for x := 0; x < code.Size; x++ {
			if code.Black(x, 0) {
				fmt.Print("1")
			} else {
				fmt.Print("0")
			}
		}
		fmt.Println()
	}
}
