#  csubptn.py -- Pythran, built -O3 -mcpu=native (2026).  The same source as
#  csubpt.py under another module name, so the native-flags build does not
#  overwrite the plain -O3 extension.
#
#  Keith's subr() from csubnp.py, unchanged, plus the one export comment that
#  tells Pythran the argument types. Pythran compiles the module ahead of
#  time to a C++ extension (csubpt.*.so) that CPython imports; without
#  Pythran the file is still ordinary Python. Driven by csubext.py.

#pythran export subr(float64[:,:], int, int, float64[:,:])
def subr(ina,nx,ny,out):
   for iy in range(ny):
      for ix in range(nx):
         out[iy,ix] = ina[iy,ix] + ix + iy
