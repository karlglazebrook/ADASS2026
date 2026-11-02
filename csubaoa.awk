# csubaoa.awk -- gawk arrays of arrays (2026 review variant of csubraw.awk).
# gawk's true multidimensional arrays, inp[iy][ix], index with the numbers
# themselves rather than a SUBSEP string; the row sub-array is taken once
# per iy.  gawk only (mawk has no arrays of arrays).
function csub(nx, ny,    ix, iy) {
   for (iy = 0; iy < ny; iy++)
      for (ix = 0; ix < nx; ix++)
         out[iy][ix] = inp[iy][ix] + ix + iy
}

BEGIN {
   nrpt = (ARGC > 1) ? ARGV[1] + 0 : 100
   nx = (ARGC > 2) ? ARGV[2] + 0 : 2000
   ny = (ARGC > 3) ? ARGV[3] + 0 : 10
   for (iy = 0; iy < ny; iy++)
      for (ix = 0; ix < nx; ix++) {
         inp[iy][ix] = nx - ix + ny - iy
         out[iy][ix] = 0.0
      }
   printf "Arrays %d by %d count %d\n", nx, ny, nrpt
   for (r = 0; r < nrpt; r++) csub(nx, ny)
   for (iy = 0; iy < ny; iy++)
      for (ix = 0; ix < nx; ix++)
         if (out[iy][ix] != inp[iy][ix] + ix + iy) {
            printf "Error: %s %d %d %s\n", out[iy][ix], ix, iy, inp[iy][ix]
            exit
         }
}
