#!/usr/bin/env python
#                          c s u b r a w _ r o w s . p y
#
#  csubraw_rows.py -- the lists-of-lists test written the way a Python
#  programmer speeds up a nested loop (2026): bind the input and output row
#  lists once per row and walk the input row with enumerate(), so the inner
#  loop does one list store and no double subscript.  Still an element loop:
#  Python code touches every element.  The input is filled with floats (see
#  csubrawf.py).  Driver, arguments and check are Keith's, from csubraw.py.
#  Runs unchanged under CPython, PyPy, GraalPy and Codon.

import sys

def subr(ina,nx,ny,out):
   for iy in range(ny):
      rin = ina[iy]
      rout = out[iy]
      for ix, v in enumerate(rin):
         rout[ix] = v + ix + iy

ny = 10
nx = 2000
nrpt = 100
if (len(sys.argv) > 1):
   nrpt = int(sys.argv[1])
   if (len(sys.argv) > 2):
      nx = int(sys.argv[2])
      if (len(sys.argv) > 3):
         ny = int(sys.argv[3])

ina = [[0.0] * nx for i in range(ny)]
for iy in range(ny):
   for ix in range(nx):
      ina[iy][ix] = float(nx - ix + ny - iy)

out = [[0.0] * nx for i in range(ny)]

print ("Arrays",nx,"by",ny,"count",nrpt)

for irpt in range(nrpt):
   subr(ina,nx,ny,out)

error = False
for iy in range(ny):
   for ix in range(nx):
      if (out[iy][ix] != (ina[iy][ix] + (ix + iy))):
         print ("Error: ",out[iy][ix],ix,iy,ina[iy][ix])
         error = True
         break
   if (error) : break
