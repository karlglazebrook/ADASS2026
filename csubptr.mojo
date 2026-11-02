# csubptr.mojo -- Mojo port keeping csubraw.mojo's List[List[Float64]]
# layout, but the kernel takes each row's raw pointer once per row instead of
# going through two bounds-checked, negative-index-normalising List
# subscripts per element. Element loop, float64.
#    mojo build csubptr.mojo -o csubptr && ./csubptr 1000 2000 10
from std.sys import argv


def subr(ina: List[List[Float64]], nx: Int, ny: Int, mut out: List[List[Float64]]):
    for iy in range(ny):
        var pin = ina[iy].unsafe_ptr()
        var pout = out[iy].unsafe_ptr()
        var fiy = Float64(iy)
        for ix in range(nx):
            pout[unsafe_offset=ix] = pin[unsafe_offset=ix] + (Float64(ix) + fiy)
def main() raises:
    var args = argv()
    var nrpt = 100
    var nx = 2000
    var ny = 10
    if len(args) > 1:
        nrpt = Int(args[1])
    if len(args) > 2:
        nx = Int(args[2])
    if len(args) > 3:
        ny = Int(args[3])

    var ina = List[List[Float64]]()
    var out = List[List[Float64]]()
    for iy in range(ny):
        var row = List[Float64](length=nx, fill=0.0)
        for ix in range(nx):
            row[ix] = Float64(nx - ix + ny - iy)
        ina.append(row^)
        out.append(List[Float64](length=nx, fill=0.0))

    print("Arrays", nx, "by", ny, "count", nrpt)

    for _ in range(nrpt):
        subr(ina, nx, ny, out)

    for iy in range(ny):
        for ix in range(nx):
            if out[iy][ix] != ina[iy][ix] + Float64(ix + iy):
                print("Error: ", out[iy][ix], ix, iy, ina[iy][ix])
                return
