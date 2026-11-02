/*  csub_vla.c -- the 2D array test kernel in plain C (C99 and later).
 *
 *  Keith's cmain.cpp notes that C "provides no way to pass such an array to
 *  a subroutine and allow the code in the subroutine to use Array[Iy][Ix]".
 *  That was true of C89 and is still true of C++, but C99 variably modified
 *  parameter types allow exactly this: the dimensions are passed first and
 *  the array parameters are declared with them. This is how a C programmer
 *  writes a 2D kernel today. Linked with cmain_c.c; build with cc, not c++.
 */

void subr (int Nx, int Ny, const float In[Ny][Nx], float Out[Ny][Nx])
{
   for (int Iy = 0; Iy < Ny; Iy++) {
      for (int Ix = 0; Ix < Nx; Ix++) {
         Out[Iy][Ix] = In[Iy][Ix] + Ix + Iy;
      }
   }
}
