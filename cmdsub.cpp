//  cmdsub.cpp -- the 2D array test kernel using C++23 std::mdspan.
//
//  std::mdspan is the standard C++ answer to "pass a 2D array to a
//  subroutine and index it as A[iy, ix]". With the default layout_right
//  the stride of the last extent is 1 at compile time, so the compiler sees
//  a contiguous row and can vectorise exactly as it does for a raw pointer.
//  Compare Boost.MultiArray (cbsub.cpp), whose strides are run-time values.
//  Linked with cmdmain.cpp. Build: c++ -std=c++23 -O3 ...

#include <mdspan>

using Grid = std::mdspan<float, std::dextents<int, 2>>;

void subr (Grid In, Grid Out)
{
   const int Ny = In.extent(0);
   const int Nx = In.extent(1);
   for (int Iy = 0; Iy < Ny; Iy++) {
      for (int Ix = 0; Ix < Nx; Ix++) {
         Out[Iy, Ix] = In[Iy, Ix] + Ix + Iy;
      }
   }
}
