#  csubpt32.py -- Pythran, float32 (2026).
#
#  csubpt.py with float32 arrays in the export and the index sum cast to
#  float32 before the add (otherwise Pythran promotes to float64 and casts
#  back).  Driven by csubext32.py, which makes float32 arrays.

import numpy

#pythran export subr(float32[:,:], int, int, float32[:,:])
def subr(ina,nx,ny,out):
   for iy in range(ny):
      for ix in range(nx):
         out[iy,ix] = ina[iy,ix] + numpy.float32(ix + iy)
