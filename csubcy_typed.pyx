# cython: language_level=3, boundscheck=False, wraparound=False
#
#  csubcy_typed.pyx -- Cython, typed (2026).
#
#  The same loop with C integer indices and C-contiguous typed memoryviews
#  (double[:, ::1]) for the two arrays, so the inner loop compiles to plain
#  C. Bounds checking and negative-index wraparound are switched off, as is
#  usual in production Cython; csubcy_checked.pyx is the identical code with
#  them left on. Driven by csubext.py.

def subr(double[:, ::1] ina, int nx, int ny, double[:, ::1] out):
   cdef int ix, iy
   for iy in range(ny):
      for ix in range(nx):
         out[iy,ix] = ina[iy,ix] + ix + iy
