package main

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

	a(c(b(), b()))
}
