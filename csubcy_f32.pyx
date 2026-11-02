# cython: language_level=3, boundscheck=False, wraparound=False, initializedcheck=False
#
#  csubcy_f32.pyx -- Cython, typed, float32 (2026).  csubcy_typed.pyx with
#  float memoryviews and Py_ssize_t indices; the index sum is cast to float
#  so the add stays single precision (clang then vectorises it 4-wide).
#  Driven by csubext32.py, which makes float32 arrays.

def subr(float[:, ::1] ina, Py_ssize_t nx, Py_ssize_t ny, float[:, ::1] out):
   cdef Py_ssize_t ix, iy
   for iy in range(ny):
      for ix in range(nx):
         out[iy,ix] = ina[iy,ix] + <float>(ix + iy)
