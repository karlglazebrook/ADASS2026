// cs_simd_proj/Program.cs -- C# with explicit SIMD, System.Numerics.Vector<double> (2026 variant).
// Element loop in SIMD lanes (2 doubles per NEON register). Each lane still
// computes in + ix + iy for its own ix; the remainder loop is scalar.
using System;
using System.Numerics;

class CsubRaw {
    static readonly Vector<double> Iota = MakeIota();
    static Vector<double> MakeIota() {
        var t = new double[Vector<double>.Count];
        for (int i = 0; i < t.Length; i++) t[i] = i;
        return new Vector<double>(t);
    }
    static void Subr(double[][] inp, int nx, int ny, double[][] outp) {
        int w = Vector<double>.Count;
        for (int iy = 0; iy < ny; iy++) {
            double[] rowIn  = inp[iy];
            double[] rowOut = outp[iy];
            int ix = 0;
            for (; ix <= nx - w; ix += w) {
                var v = new Vector<double>(rowIn, ix);
                (v + (Iota + new Vector<double>((double)(ix + iy)))).CopyTo(rowOut, ix);
            }
            for (; ix < nx; ix++) rowOut[ix] = rowIn[ix] + ix + iy;
        }
    }
    static int Main(string[] args) {
        int nrpt = 1000, nx = 2000, ny = 10;
        if (args.Length > 0) nrpt = int.Parse(args[0]);
        if (args.Length > 1) nx   = int.Parse(args[1]);
        if (args.Length > 2) ny   = int.Parse(args[2]);
        var inp  = new double[ny][];
        var outp = new double[ny][];
        for (int iy = 0; iy < ny; iy++) {
            inp[iy]  = new double[nx];
            outp[iy] = new double[nx];
            for (int ix = 0; ix < nx; ix++) inp[iy][ix] = nx - ix + ny - iy;
        }
        Console.WriteLine($"Arrays {nx} by {ny} count {nrpt} lanes {Vector<double>.Count}");
        for (int r = 0; r < nrpt; r++) Subr(inp, nx, ny, outp);
        for (int iy = 0; iy < ny; iy++)
            for (int ix = 0; ix < nx; ix++)
                if (outp[iy][ix] != inp[iy][ix] + ix + iy) {
                    Console.WriteLine($"Error: {outp[iy][ix]} {ix} {iy} {inp[iy][ix]}");
                    return 1;
                }
        return 0;
    }
}
