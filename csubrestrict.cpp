//  csubrestrict.cpp -- Keith's csub.cpp with __restrict__ row pointers
//  (2026 review variant; ChatGPT recommendation).
//
//  States the non-aliasing of In and Out that is already true in cmain.cpp,
//  so the compiler need not emit a runtime overlap check before the
//  vectorised loop, and walks each row through a pointer rather than
//  recomputing Iy*Nx+Ix. The arithmetic is Keith's: (in + float(x)) + fy,
//  two separately rounded float adds, no reassociation. Drop-in replacement
//  for csub.cpp; link with cmain.cpp.

void subr (float* __restrict__ in, int nx, int ny, float* __restrict__ out)
{
   for (int y = 0; y < ny; ++y) {
      const float fy = static_cast<float>(y);
      const float* a = in + static_cast<long long>(y) * nx;
      float* b = out + static_cast<long long>(y) * nx;
      for (int x = 0; x < nx; ++x) {
         b[x] = (a[x] + static_cast<float>(x)) + fy;
      }
   }
}
