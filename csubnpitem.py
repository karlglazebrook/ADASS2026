#!/usr/bin/env python3
#                          c s u b n p i t e m . p y
#
#  csubnpitem.py -- numpy element loop with .item() reads (2026).
#  ina[iy,ix] builds a numpy.float64 scalar and the following "+ ix" runs
#  numpy's scalar-math dispatch; ina.item(iy,ix) returns a plain Python
#  float so both adds are interpreter float adds.  The store is unchanged
#  (numpy 2 removed itemset).  Otherwise Keith's csubnp.py.

import numpy
import sys

DTYPE = numpy.float64

def subr(ina,nx,ny,out):
   for iy in range(ny):
      for ix in range(nx):
         out[iy,ix] = ina.item(iy,ix) + ix + iy

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
