# csubsimd32.mojo -- Mojo port, flat List[Float32] (32-bit); the inner loop steps through
# each row a SIMD vector at a time (W = 4 Float32 lanes on NEON) with a scalar
# tail, using the raw list pointer. This is how a Mojo programmer writes a
# numeric inner loop: the compiler does not auto-vectorise the scalar form.
# Element loop (explicit SIMD), float64, serial.
#    mojo build csubsimd32.mojo -o csubsimd32 && ./csubsimd32 1000 2000 10
from std.sys import argv, simd_width_of
from std.math import iota

comptime W = simd_width_of[DType.float32]()


def subr(ina: List[Float32], nx: Int, ny: Int, mut out: List[Float32]):
    var pin = ina.unsafe_ptr()
    var pout = out.unsafe_ptr()
    for iy in range(ny):
        var base = iy * nx
        var fiy = Float32(iy)
        var ix = 0
        while ix + W <= nx:
            var v = pin.unsafe_load[width=W](base + ix) + (iota[DType.float32, W](Float32(ix)) + fiy)
            pout.unsafe_store(base + ix, v)
            ix += W
        while ix < nx:
            pout[unsafe_offset = base + ix] = pin[unsafe_offset = base + ix] + (Float32(ix) + fiy)
            ix += 1
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
    var ina = List[Float32](length=nx * ny, fill=0.0)
    var out = List[Float32](length=nx * ny, fill=0.0)
    for iy in range(ny):
        for ix in range(nx):
            ina[iy * nx + ix] = Float32(nx - ix + ny - iy)
    print("Arrays", nx, "by", ny, "count", nrpt)
    for _ in range(nrpt):
        subr(ina, nx, ny, out)
    for iy in range(ny):
        for ix in range(nx):
            if out[iy * nx + ix] != ina[iy * nx + ix] + Float32(ix + iy):
                print("Error: ", out[iy * nx + ix], ix, iy, ina[iy * nx + ix])
                return
