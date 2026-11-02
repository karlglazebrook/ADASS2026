//  cmdmain.cpp -- Keith's cmain.cpp driving the std::mdspan kernel in
//  cmdsub.cpp (C++23). Same setup and check as cmain.cpp; the arrays are
//  one contiguous block each, viewed through a 2D mdspan.

#include <stdio.h>
#include <stdlib.h>
#include <mdspan>

using Grid = std::mdspan<float, std::dextents<int, 2>>;

void subr (Grid In, Grid Out);

int main (int argc, char* argv[])
{
   int Nrpt = 1000;
   int Nx = 2000;
   int Ny = 10;
   if (argc > 1) Nrpt = atoi(argv[1]);
   if (argc > 2) Nx = atoi(argv[2]);
   if (argc > 3) Ny = atoi(argv[3]);

   float* InData = (float*) malloc ((size_t)Nx * Ny * sizeof(float));
   float* OutData = (float*) malloc ((size_t)Nx * Ny * sizeof(float));
   Grid In(InData, Ny, Nx);
   Grid Out(OutData, Ny, Nx);

   for (int Iy = 0; Iy < Ny; Iy++) {
      for (int Ix = 0; Ix < Nx; Ix++) {
         In[Iy, Ix] = float(Nx - Ix + Ny - Iy);
      }
   }
   printf ("Arrays have %d rows of %d columns, repeats = %d\n",Ny,Nx,Nrpt);

   for (int Loop = 0; Loop < Nrpt; Loop++) {
      subr (In,Out);
   }

   bool Error = false;
   for (int Iy = 0; Iy < Ny; Iy++) {
      for (int Ix = 0; Ix < Nx; Ix++) {
         if (Out[Iy, Ix] != In[Iy, Ix] + Ix + Iy) {
            Error = true;
            printf ("Error Out[%d][%d] = %f, not %f\n",Iy,Ix,
                                   Out[Iy, Ix],float(In[Iy, Ix] + Ix + Iy));
            break;
         }
      }
      if (Error) break;
   }
   return 0;
}
