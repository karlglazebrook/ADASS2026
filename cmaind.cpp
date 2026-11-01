//  cmaind.cpp -- Keith's cmain.cpp in double precision (2026); see csubd.cpp.

#include <stdio.h>
#include <stdlib.h>

//  subr() is the subroutine that does the actual array manipulation. It has to
//  be compiled separately to prevent a compiler optimising it away entirely.

void subr (double* In, int Nx, int Ny, double* Out);

int main (int argc, char* argv[])
{
   //  Set the array dimensions and repeat count either from the default values
   //  or values supplied on the command line.
   
   int Nrpt = 1000;
   int Nx = 2000;
   int Ny = 10;
   if (argc > 1) Nrpt = atoi(argv[1]);
   if (argc > 2) Nx = atoi(argv[2]);
   if (argc > 3) Ny = atoi(argv[3]);
   
   //  Allocate memory for the input array In and the output array Out.
   
   double* In = (double*) malloc (Nx * Ny * sizeof(double));
   double* Out = (double*) malloc (Nx * Ny * sizeof(double));
   
   //  We set the elements of the input array to some set of values - it doesn't
   //  matter what, just some values we can use to check the array manipulation
   //  on. This uses the sum of the row and column indices in descending order.
   //  We don't need to initialise the output array.
   
   for (int Iy = 0; Iy < Ny; Iy++) {
      for (int Ix = 0; Ix < Nx; Ix++) {
         In[Iy * Nx + Ix] = double(Nx - Ix + Ny - Iy);
      }
   }
   printf ("Arrays have %d rows of %d columns, repeats = %d\n",Ny,Nx,Nrpt);

   //  Repeat the call to the manipulating subroutine. A compiler can't optimise
   //  this out, as it doesn't know that the results will be the same every
   //  time.
   
   for (int Loop = 0; Loop < Nrpt; Loop++) {
      subr (In,Nx,Ny,Out);
   }
   
   //  Check that we got the expected results.
   
   bool Error = false;
   for (int Ix = 0; Ix < Nx; Ix++) {
      for (int Iy = 0; Iy < Ny; Iy++) {
         if (Out[Iy * Nx + Ix] != (In[Iy * Nx + Ix] + Ix + Iy)) {
            Error = true;
            printf ("Error Out[%d][%d] = %f, not %f\n",Ix,Iy,
                  Out[Iy * Nx + Ix],In[Iy * Nx + Ix] + double(Ix + Iy));
            break;
         }
      }
      if (Error) break;
   }
   return 0;
}
