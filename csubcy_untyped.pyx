#  csubcy_untyped.pyx -- Cython, untyped (2026).
#
#  Keith's subr() from csubnp.py, unchanged, compiled by Cython. With no type
#  declarations every operation still goes through the CPython API (boxed
#  integers, numpy indexing), so this measures what compiling alone buys.
#  Driven by csubext.py.

def subr(ina,nx,ny,out):
   for iy in range(ny):
      for ix in range(nx):
         out[iy,ix] = ina[iy,ix] + ix + iy
