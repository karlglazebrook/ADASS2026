// cs_f32_proj/Program.cs -- C# float32 variant of cs_proj (2026).
// Identical to cs_proj/Program.cs except the arrays are float[][] (32-bit),
// matching Keith's Java, C and Fortran kernels. float + int promotes to float.
using System;

class CsubRaw {
    static void Subr(float[][] inp, int nx, int ny, float[][] outp) {
        for (int iy = 0; iy < ny; iy++) {
            float[] rowIn  = inp[iy];
            float[] rowOut = outp[iy];
            for (int ix = 0; ix < nx; ix++) {
                rowOut[ix] = rowIn[ix] + ix + iy;
            }
        }
    }

    static int Main(string[] args) {
        int nrpt = 1000, nx = 2000, ny = 10;
        if (args.Length > 0) nrpt = int.Parse(args[0]);
        if (args.Length > 1) nx   = int.Parse(args[1]);
        if (args.Length > 2) ny   = int.Parse(args[2]);
        var inp  = new float[ny][];
        var outp = new float[ny][];
        for (int iy = 0; iy < ny; iy++) {
            inp[iy]  = new float[nx];
            outp[iy] = new float[nx];
            for (int ix = 0; ix < nx; ix++) inp[iy][ix] = nx - ix + ny - iy;
        }
        Console.WriteLine($"Arrays {nx} by {ny} count {nrpt}");
        for (int r = 0; r < nrpt; r++) Subr(inp, nx, ny, outp);
        for (int iy = 0; iy < ny; iy++)
            for (int ix = 0; ix < nx; ix++)
                if (outp[iy][ix] != inp[iy][ix] + (ix + iy)) {
                    Console.WriteLine($"Error: {outp[iy][ix]} {ix} {iy} {inp[iy][ix]}");
                    return 1;
                }
        return 0;
    }
}
