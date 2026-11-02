//  cbsubdata.cpp -- the Boost.MultiArray kernel scanning the contiguous
//  storage directly (2026 review variant; ChatGPT recommendation).
//
//  cbmain.cpp creates owning multi_arrays in the default C storage order, so
//  the elements are one contiguous row-major block. This variant takes
//  In.data()/Out.data() once and indexes the block itself, measuring Boost
//  as the owner of the array rather than through its per-element proxy
//  indexing (cbsub.cpp). The shape check guards the assumption. Arithmetic
//  is Keith's two separately rounded float adds. Not valid for reindexed or
//  non-C-order views. Drop-in replacement for cbsub.cpp; link with cbmain.cpp.

#include "boost/multi_array.hpp"
#include <stdexcept>
#include <cstddef>

typedef boost::multi_array<float,2> Array2DType;

void subr (Array2DType& in, int nx, int ny, Array2DType& out)
{
   if (nx <= 0 || ny <= 0 || in.shape()[0] != static_cast<std::size_t>(ny) ||
       in.shape()[1] != static_cast<std::size_t>(nx) ||
       out.shape()[0] != in.shape()[0] || out.shape()[1] != in.shape()[1])
      throw std::invalid_argument("shape mismatch");
   const float* a = in.data();
   float* b = out.data();
   for (int y = 0; y < ny; ++y) {
      const std::size_t base = static_cast<std::size_t>(y) * nx;
      for (int x = 0; x < nx; ++x) {
         b[base + x] = (a[base + x] + static_cast<float>(x)) + static_cast<float>(y);
      }
   }
}
