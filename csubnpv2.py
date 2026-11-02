#!/usr/bin/env python3
#                            c s u b n p v 2 . p y
#
#  csubnpv2.py -- numpy row vectors, idiomatic form (2026).  As csubnpv.py
#  (one whole-row array expression per row) but: the index vector is made
#  in the array's own dtype, so the add is float64 + float64 rather than
#  numpy's buffered int64->float64 casting loop; the result is written
#  straight into the output row with numpy.add(..., out=...); and the
#  index vector is advanced in place (csubnpv.py's numpy.array(nx).fill(1)
#  is a 0-d array, not a vector, and incr = incr + ones reallocates).
#  Whole-array (per row) variant.  Driver and check are Keith's.

import numpy
import sys

DTYPE = numpy.float64

def subr(ina,nx,ny,out):
   incr = numpy.arange(nx, dtype=ina.dtype)
   for iy in range(ny):
      numpy.add(ina[iy], incr, out=out[iy])
      incr += 1

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
