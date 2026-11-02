#!/usr/bin/env python3
#                         c s u b e x t 3 2 . p y
#
#  Float32 driver for the compiled-Python variants of the numpy element-access
#  test (2026): csubext.py with both arrays made as numpy.float32, for the
#  float32 extension modules csubcy_f32 (Cython) and csubpt32 (Pythran).
#  Otherwise identical to csubext.py. It is csubnp-numba.py with the subroutine moved out into a
#  separately compiled extension module, named as the first argument:
#
#     python csubext32.py csubcy_f32  1000 2000 10   (Cython, typed float32)
#     python csubext32.py csubpt32    1000 2000 10   (Pythran, float32)
#
#  The remaining arguments are the usual repeat count, nx and ny that Run.py
#  appends. Each module provides subr(ina,nx,ny,out), and the timing and the
#  final check are exactly as in csubnp-numba.py.

import importlib
import numpy
import sys

subr = importlib.import_module(sys.argv[1]).subr
args = sys.argv[1:]

ny = 10
nx = 2000
nrpt = 100
if (len(args) > 1):
   nrpt = int(args[1])
   if (len(args) > 2):
      nx = int(args[2])
      if (len(args) > 3):
         ny = int(args[3])

ina = numpy.zeros((ny,nx), dtype=numpy.float32)
for iy in range(ny):
   for ix in range(nx):
      ina[iy,ix] = nx - ix + ny - iy

out = numpy.zeros((ny,nx), dtype=numpy.float32)

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
