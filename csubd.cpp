//  csubd.cpp -- Keith's csub.cpp in double precision (2026).
//
//  Identical to csub.cpp except that float is double. Keith's C, Fortran,
//  Julia and assembler kernels are 32-bit; most of the 2026 ports are 64-bit,
//  and NEON holds four floats but only two doubles per register. Built with
//  the same flags as csub.cpp, this measures that difference directly.
//  Linked with cmaind.cpp.

void subr (double* In, int Nx, int Ny, double* Out)
{
   for (int Iy = 0; Iy < Ny; Iy++) {
      for (int Ix = 0; Ix < Nx; Ix++) {
         Out[Iy * Nx + Ix] = In[Iy * Nx + Ix] + Ix + Iy;
      }
   }
}
