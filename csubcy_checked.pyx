# cython: language_level=3
#
#  csubcy_checked.pyx -- Cython, typed, with Cython's default safety checks
#  (2026). Identical to csubcy_typed.pyx except that bounds checking and
#  negative-index wraparound are left on. Driven by csubext.py.

def subr(double[:, ::1] ina, int nx, int ny, double[:, ::1] out):
   cdef int ix, iy
   for iy in range(ny):
      for ix in range(nx):
         out[iy,ix] = ina[iy,ix] + ix + iy
