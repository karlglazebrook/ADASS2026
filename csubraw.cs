// csubraw.cs — C# / .NET port of csubraw.py / csubraw.rb.
// 2D double array as a jagged double[][].  iy outer / ix inner so each
// row is a contiguous double[] walked sequentially.

using System;

class CsubRaw {
    static void Subr(double[][] inp, int nx, int ny, double[][] outp) {
        for (int iy = 0; iy < ny; iy++) {
            double[] rowIn  = inp[iy];
            double[] rowOut = outp[iy];
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

        var inp  = new double[ny][];
        var outp = new double[ny][];
        for (int iy = 0; iy < ny; iy++) {
            inp[iy]  = new double[nx];
            outp[iy] = new double[nx];
            for (int ix = 0; ix < nx; ix++) {
                inp[iy][ix] = nx - ix + ny - iy;
            }
        }

        Console.WriteLine($"Arrays {nx} by {ny} count {nrpt}");
        for (int r = 0; r < nrpt; r++) Subr(inp, nx, ny, outp);

        for (int iy = 0; iy < ny; iy++) {
            for (int ix = 0; ix < nx; ix++) {
                if (outp[iy][ix] != inp[iy][ix] + ix + iy) {
                    Console.WriteLine(
                        $"Error: {outp[iy][ix]} {ix} {iy} {inp[iy][ix]}");
                    return 0;
                }
            }
        }
        return 0;
    }
}
