# csubraw.mojo -- Mojo port (2026).
#
# Keith's csubraw.py list version in Mojo: the arrays are lists of lists of
# Float64, indexed element by element, exactly as in the Python. Mojo's List
# is a typed, contiguous growable array, and subr is a typed function, so
# the loop compiles to native code (via MLIR and LLVM) with no interpreter.
#
#    mojo build csubraw.mojo -o csub_mojo && ./csub_mojo 1000 2000 10

from std.sys import argv


def subr(ina: List[List[Float64]], nx: Int, ny: Int, mut out: List[List[Float64]]):
    for iy in range(ny):
        for ix in range(nx):
            out[iy][ix] = ina[iy][ix] + Float64(ix + iy)


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
