package main

import "fmt"

type R interface {
	foo()
}

type U64 uint64

func (u64 U64) foo() {
	println("bar")
}

func bar(r R) {
	r.foo()
}

func main() {
	x := 2
	var r R
	r = 1 << x

	r.foo()

	fmt.Printf("%T\n", r) // TODO: should output main.U64 rather than the underlying type
}

// Error:
// main/files/types/shift_b6.gno:22:2: <untyped> bigint does not implement main.R (missing method foo)
