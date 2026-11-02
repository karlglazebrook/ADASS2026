//  csubsd.cpp -- csubs.cpp (single-add kernel) in double precision (2026).
//
//  The float64 twin of csubs.cpp: one integer add, one conversion and one
//  double add per element, instead of the two rounded adds in csubd.cpp.
//  Bit-identical to csubd.cpp while Ix+Iy < 2^53. Drop-in replacement for
//  csubd.cpp; link with cmaind.cpp.

void subr (double* In, int Nx, int Ny, double* Out)
{
   for (int Iy = 0; Iy < Ny; Iy++) {
      const double* in  = In  + (long)Iy * Nx;
      double*       out = Out + (long)Iy * Nx;
      for (int Ix = 0; Ix < Nx; Ix++) {
         out[Ix] = in[Ix] + double(Ix + Iy);
      }
   }
}
