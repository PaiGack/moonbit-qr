package main

import (
	"fmt"
)

func main() {
	text := "HELLO WORLD"
	data := []byte(text)
	
	fmt.Println("Encoding:", text)
	fmt.Printf("Data bytes (%d): ", len(data))
	for _, b := range data {
		fmt.Printf("%02X ", b)
	}
	fmt.Println()
	
	fmt.Println("\nBinary representation:")
	for i, b := range data {
		fmt.Printf("Byte %2d (%c): %08b\n", i, b, b)
	}
}
