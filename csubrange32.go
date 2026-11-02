// csubrange32.go -- csubrange.go in float32 (2026 review variant): the
// inner loop ranges over the input row and the output row is re-sliced to the
// same length first, which is the idiom that lets the compiler prove both
// index expressions in range and drop the bounds checks (no -gcflags=-B
// needed). Element loop, float32.
package main

import (
	"fmt"
	"os"
	"strconv"
)

func subr(in [][]float32, nx, ny int, out [][]float32) {
	for iy := 0; iy < ny; iy++ {
		rowIn := in[iy][:nx]
		rowOut := out[iy][:len(rowIn)]
		fiy := float32(iy)
		for ix, v := range rowIn {
			rowOut[ix] = v + float32(ix) + fiy
		}
	}
}

func atoiOr(s string, dflt int) int {
	if v, err := strconv.Atoi(s); err == nil {
		return v
	}
	return dflt
}

func main() {
	nrpt, nx, ny := 100, 2000, 10
	if len(os.Args) > 1 {
		nrpt = atoiOr(os.Args[1], nrpt)
	}
	if len(os.Args) > 2 {
		nx = atoiOr(os.Args[2], nx)
	}
	if len(os.Args) > 3 {
		ny = atoiOr(os.Args[3], ny)
	}
	in := make([][]float32, ny)
	out := make([][]float32, ny)
	for iy := 0; iy < ny; iy++ {
		in[iy] = make([]float32, nx)
		out[iy] = make([]float32, nx)
		for ix := 0; ix < nx; ix++ {
			in[iy][ix] = float32(nx - ix + ny - iy)
		}
	}
	fmt.Printf("Arrays %d by %d count %d\n", nx, ny, nrpt)
	for r := 0; r < nrpt; r++ {
		subr(in, nx, ny, out)
	}
	for iy := 0; iy < ny; iy++ {
		for ix := 0; ix < nx; ix++ {
			if out[iy][ix] != in[iy][ix]+float32(ix)+float32(iy) {
				fmt.Printf("Error: %v %d %d %v\n", out[iy][ix], ix, iy, in[iy][ix])
				return
			}
		}
	}
}
