package main

import "fmt"

func main() {
	data := 11
	d := data << 10
	gen := 0b10100110111
	
	fmt.Printf("data = %d = 0b%05b\n", data, data)
	fmt.Printf("d初始 = %d = 0b%015b\n", d, d)
	fmt.Printf("gen = %d = 0b%011b\n\n", gen, gen)
	
	for i := 0; i < 5; i++ {
		checkPos := 14 - i
		mask := 1 << checkPos
		checkVal := d & mask
		fmt.Printf("i=%d, 检查位%d, d=%d (0b%015b), 检查值=%d\n", 
			i, checkPos, d, d, checkVal)
		if checkVal != 0 {
			shift := 4 - i
			xorVal := gen << shift
			fmt.Printf("  → XOR: d ^ (gen << %d) = %d ^ %d\n", shift, d, xorVal)
			d ^= xorVal
			fmt.Printf("  → 结果: d=%d (0b%015b)\n", d, d)
		}
	}
	
	format := (data << 10) | d
	finalFormat := format ^ 0b101010000010010
	
	fmt.Printf("\n最终:\n")
	fmt.Printf("d = %d = 0b%010b\n", d, d)
	fmt.Printf("format (XOR前) = %d = 0b%015b = 0x%X\n", format, format, format)
	fmt.Printf("format (XOR后) = %d = 0b%015b = 0x%X\n", finalFormat, finalFormat, finalFormat)
}
