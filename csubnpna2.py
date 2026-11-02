#!/usr/bin/env python3
#                           c s u b n p n a 2 . p y
#
#  csubnpna2.py -- numpy whole-array form, in place, float64 (2026).  As
#  csubnpna.py but with no temporaries: the first add writes straight into
#  out with numpy.add(..., out=out) and the second is an in-place += of the
#  broadcast row-index column.  The index vectors are made in the array's
#  own dtype so no int64->float casting loop runs.  Two passes over out
#  instead of csubnpna.py's two full-size temporaries plus a copy.
#  Both adds still happen inside subr on every repeat.  Driver and check
#  are Keith's.

import numpy
import sys

DTYPE = numpy.float64

def subr(ina,nx,ny,out):
   numpy.add(ina, numpy.arange(nx, dtype=ina.dtype), out=out)
   out += numpy.arange(ny, dtype=ina.dtype)[:,None]

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
