#!/usr/bin/env python3
#                        c s u b n p - n u m b a 3 2 . p y
#
#  csubnp-numba32.py -- csubnp-numba.py in float32 (2026).  The arrays are
#  float32 and the index sum is cast to float32 before the add; without the
#  cast numba promotes float32 + int64 to float64 and casts back, which
#  stops the 4-wide NEON loop.  @numba.njit is the explicit nopython
#  spelling of @numba.jit (the default since numba 0.59).  No cache=True:
#  the harness's one-repeat run must compile too, so the two cancel.

import numba
import numpy
import sys

DTYPE = numpy.float32

@numba.njit
def subr(ina,nx,ny,out):
   for iy in range(ny):
      for ix in range(nx):
         out[iy,ix] = ina[iy,ix] + numba.float32(ix + iy)

ny = 10
nx = 2000
nrpt = 100
if (len(sys.argv) > 1):
   nrpt = int(sys.argv[1])
   if (len(sys.argv) > 2):
      nx = int(sys.argv[2])
      if (len(sys.argv) > 3):
         ny = int(sys.argv[3])

ina = numpy.zeros((ny,nx), dtype=DTYPE)
for iy in range(ny):
   for ix in range(nx):
      ina[iy,ix] = nx - ix + ny - iy

out = numpy.zeros((ny,nx), dtype=DTYPE)

print ("Arrays",nx,"by",ny,"count",nrpt)

for irpt in range(nrpt):
   subr(ina,nx,ny,out)

error = False
for iy in range(ny):
   for ix in range(nx):
      if (out[iy,ix] != (ina[iy,ix] + (ix + iy))):
         print ("Error: ",out[iy,ix],ix,iy,ina[iy,ix])
         error = True
         break
   if (error) : break
