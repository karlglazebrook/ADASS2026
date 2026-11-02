# cython: language_level=3, boundscheck=False, wraparound=False, initializedcheck=False
# distutils: extra_compile_args = -O3 -mcpu=native
#
#  csubcy_native.pyx -- Cython, typed, compiled -O3 -mcpu=native (2026).
#  The same kernel as csubcy_typed.pyx; the distutils line above replaces
#  the -O2 that cythonize inherits from the Python build, for parity with
#  the "-O3 native" C rows.  Driven by csubext.py.

def subr(double[:, ::1] ina, int nx, int ny, double[:, ::1] out):
   cdef int ix, iy
   for iy in range(ny):
      for ix in range(nx):
         out[iy,ix] = ina[iy,ix] + ix + iy
