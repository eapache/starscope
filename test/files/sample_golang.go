package main

import "fmt"

var (
	v1, v2 int = 3, 4
)

var raw = []byte{
	0x00, 0x01,
	0x02, 0x03,
}

const (
	Sunday = iota
	Monday
)

type foo interface {
	bar() int
}

func a(c int) int {
	return 3
}

func b() int {
	return 0
}

func c(a, b int) int {
	return 1
}

func ttt() (int, int) {
	return 1, 2
}

func main() {
	var (
		q int
		t string
	)
	x := a(1)
	y := b()
	z := c(a(q), b())
	n, m := ttt()
	m, x = ttt()

	if m == x {
		v1 = v2
	}

	a(c(b(), b()))

	fmt.Println(n)
	fmt.Println(t)
	fmt.Println(y)
	fmt.Println(z)
}
