// csubraw32.d - D port in float (32-bit), 2026 review variant of csubraw.d.
// Compile with LDC for LLVM-backed optimisation:
//   ldc2 -O3 -release -boundscheck=off csubraw.d -of=csub_d
import std.stdio;
import std.conv : to;

void subr(float[][] inp, size_t nx, size_t ny, float[][] outp) {
    foreach (iy; 0 .. ny) {
        auto rowIn  = inp[iy];
        auto rowOut = outp[iy];
        immutable fiy = cast(float) iy;
        foreach (ix; 0 .. nx) {
            rowOut[ix] = rowIn[ix] + cast(float) ix + fiy;
        }
    }
}

int main(string[] args) {
    size_t nrpt = args.length > 1 ? args[1].to!size_t : 1000;
    size_t nx   = args.length > 2 ? args[2].to!size_t : 2000;
    size_t ny   = args.length > 3 ? args[3].to!size_t : 10;

    auto inp  = new float[][](ny, nx);
    auto outp = new float[][](ny, nx);
    foreach (iy; 0 .. ny)
        foreach (ix; 0 .. nx)
            inp[iy][ix] = cast(float) (nx - ix + ny - iy);

    writefln("Arrays %d by %d count %d", nx, ny, nrpt);

    foreach (r; 0 .. nrpt) subr(inp, nx, ny, outp);

    foreach (iy; 0 .. ny) {
        foreach (ix; 0 .. nx) {
            immutable want = inp[iy][ix] + cast(float) ix + cast(float) iy;
            if (outp[iy][ix] != want) {
                writefln("Error: %s %d %d %s", outp[iy][ix], ix, iy, inp[iy][ix]);
                return 0;
            }
        }
    }
    return 0;
}
