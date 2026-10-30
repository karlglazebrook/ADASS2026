// csubraw.go — Go port of csubraw.py / csubraw.rb.
// 2D float64 array as a slice-of-slices.  iy outer / ix inner so each row
// is a contiguous slice walked sequentially.

package main

import (
	"fmt"
	"os"
	"strconv"
)

func subr(in [][]float64, nx, ny int, out [][]float64) {
	for iy := 0; iy < ny; iy++ {
		rowIn := in[iy]
		rowOut := out[iy]
		for ix := 0; ix < nx; ix++ {
			rowOut[ix] = rowIn[ix] + float64(ix) + float64(iy)
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

	in := make([][]float64, ny)
	out := make([][]float64, ny)
	for iy := 0; iy < ny; iy++ {
		in[iy] = make([]float64, nx)
		out[iy] = make([]float64, nx)
		for ix := 0; ix < nx; ix++ {
			in[iy][ix] = float64(nx - ix + ny - iy)
		}
	}

	fmt.Printf("Arrays %d by %d count %d\n", nx, ny, nrpt)

	for r := 0; r < nrpt; r++ {
		subr(in, nx, ny, out)
	}

	for iy := 0; iy < ny; iy++ {
		for ix := 0; ix < nx; ix++ {
			if out[iy][ix] != in[iy][ix]+float64(ix)+float64(iy) {
				fmt.Printf("Error: %v %d %d %v\n", out[iy][ix], ix, iy, in[iy][ix])
				return
			}
		}
	}
}
