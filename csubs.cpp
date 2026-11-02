//  csubs.cpp -- Keith's csub.cpp with the two index adds folded into one.
//
//  Keith's kernel is written as  In + Ix + Iy, which C++ evaluates as
//  (In + float(Ix)) + float(Iy): two conversions and two rounded float adds
//  per element, and the compiler may not reassociate them. Keith's NEON
//  assembler already adds a single precomputed float(Ix+Iy). This variant
//  does the same in C++: one integer add, one conversion, one float add.
//  Results are bit-identical as long as Ix+Iy < 2^24, which it is here.
//  Drop-in replacement for csub.cpp; link with cmain.cpp.

void subr (float* In, int Nx, int Ny, float* Out)
{
   for (int Iy = 0; Iy < Ny; Iy++) {
      const float* in  = In  + (long)Iy * Nx;
      float*       out = Out + (long)Iy * Nx;
      for (int Ix = 0; Ix < Nx; Ix++) {
         out[Ix] = in[Ix] + float(Ix + Iy);
      }
   }
}
