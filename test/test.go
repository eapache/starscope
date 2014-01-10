package main

func a(c int) int {
	return 3
}

func b() int {
	return 0
}

func c(a,b int) int {
	return 1
}

func main() {
	x := a(1)
	y := b()
	z := c(a(b()), b())

	a(c(b(), b()))
}
