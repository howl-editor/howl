package main

import "fmt"

// Integers
var i int = 1
var ui uint = 0x8
var i8 int = 127
var i16 int = 32767
var i32 int32 = 2147483647
var i64 int64 = 9223372036854775807

// Floats
var f32 float32 = 3.1
var f64 float64 = 3.234e123

// Complex
var c64 complex64 = complex(1, 2)
var c128 complex128 = complex(-1, 3)

// Others
var b byte = 'a'
var r rune = '☺'

// Strings
var s1 = "string \"quote\""
var s2 = `raw
"multiline"
string`

// Map
var m = map[string]int{
	"1": 1,
	"2": 2,
}

// Type defs
type V string
type X struct {
	number int
	text   string
}

// List
var l = []int{1, 2, 3}

func main() {
	/* multiline
	   comment */
	var x *X
	x = nil
	x = new(X)
	x.Hello(42, 3)
}

func operators() {
	fmt.Println(i + 1 - 2*3/4 ^ 5%6)
	fmt.Println(i < 1 && i > 2 || i >= 1 || i <= 3 || i == 4 || !(i != 5) && true || !false)
}

func (x *X) Hello(n int, times int) {
	for i := 0; i < times; i += 1 {
		fmt.Printf("Hello, %d\n", n+i)
	}
}
