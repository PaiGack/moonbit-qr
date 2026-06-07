package main

import (
	"fmt"
	"rsc.io/qr"
	"rsc.io/qr/coding"
)

func main() {
	text := "HELLO WORLD"

	fmt.Println("=== Testing qr.Encode (auto mode selection) ===")
	code1, _ := qr.Encode(text, qr.L)
	fmt.Print("Row 0: ")
	for x := 0; x < code1.Size; x++ {
		if code1.Black(x, 0) {
			fmt.Print("1")
		} else {
			fmt.Print("0")
		}
	}
	fmt.Println()

	fmt.Println("\n=== Testing with explicit String (byte) mode ===")
	enc := coding.String(text)
	plan, _ := coding.NewPlan(1, coding.L, 0)
	code2, _ := plan.Encode(enc)
	fmt.Print("Row 0: ")
	for x := 0; x < code2.Size; x++ {
		if code2.Black(x, 0) {
			fmt.Print("1")
		} else {
			fmt.Print("0")
		}
	}
	fmt.Println()

	fmt.Println("\n=== Testing with Alpha (alphanumeric) mode ===")
	enc2 := coding.Alpha(text)
	plan2, _ := coding.NewPlan(1, coding.L, 0)
	code3, _ := plan2.Encode(enc2)
	fmt.Print("Row 0: ")
	for x := 0; x < code3.Size; x++ {
		if code3.Black(x, 0) {
			fmt.Print("1")
		} else {
			fmt.Print("0")
		}
	}
	fmt.Println()
}
