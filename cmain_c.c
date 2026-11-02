/*  cmain_c.c -- Keith's cmain.cpp translated to plain C, driving the C99
 *  variable-length-array kernel in csub_vla.c. Same setup and check.
 */

#include <stdio.h>
#include <stdlib.h>

void subr (int Nx, int Ny, const float In[Ny][Nx], float Out[Ny][Nx]);

int main (int argc, char* argv[])
{
   int Nrpt = 1000;
   int Nx = 2000;
   int Ny = 10;
   if (argc > 1) Nrpt = atoi(argv[1]);
   if (argc > 2) Nx = atoi(argv[2]);
   if (argc > 3) Ny = atoi(argv[3]);

   float (*In)[Nx]  = malloc (sizeof(float[Ny][Nx]));
   float (*Out)[Nx] = malloc (sizeof(float[Ny][Nx]));

   for (int Iy = 0; Iy < Ny; Iy++) {
      for (int Ix = 0; Ix < Nx; Ix++) {
         In[Iy][Ix] = (float)(Nx - Ix + Ny - Iy);
      }
   }
   printf ("Arrays have %d rows of %d columns, repeats = %d\n",Ny,Nx,Nrpt);

   for (int Loop = 0; Loop < Nrpt; Loop++) {
      subr (Nx,Ny,In,Out);
   }

   int Error = 0;
   for (int Iy = 0; Iy < Ny; Iy++) {
      for (int Ix = 0; Ix < Nx; Ix++) {
         if (Out[Iy][Ix] != In[Iy][Ix] + Ix + Iy) {
            Error = 1;
            printf ("Error Out[%d][%d] = %f, not %f\n",Iy,Ix,
                                   Out[Iy][Ix],(float)(In[Iy][Ix] + Ix + Iy));
            break;
         }
      }
      if (Error) break;
   }
   return 0;
}
