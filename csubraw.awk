# csubraw.awk -- awk port (2026).
#
# awk's arrays are associative; a 2D index inp[iy,ix] is the string key
# iy SUBSEP ix, so every element access hashes a string. The whole program
# runs in BEGIN, with the harness's numbers as arguments. Run.py runs it
# with mawk (a fast bytecode interpreter) and gawk (GNU awk):
#    mawk -f csubraw.awk 100 2000 10

function csub(nx, ny,    ix, iy) {
   for (iy = 0; iy < ny; iy++)
      for (ix = 0; ix < nx; ix++)
         out[iy, ix] = inp[iy, ix] + ix + iy
}

BEGIN {
   nrpt = (ARGC > 1) ? ARGV[1] + 0 : 100
   nx = (ARGC > 2) ? ARGV[2] + 0 : 2000
   ny = (ARGC > 3) ? ARGV[3] + 0 : 10
   for (iy = 0; iy < ny; iy++)
      for (ix = 0; ix < nx; ix++) {
         inp[iy, ix] = nx - ix + ny - iy
         out[iy, ix] = 0.0
      }
   printf "Arrays %d by %d count %d\n", nx, ny, nrpt
   for (r = 0; r < nrpt; r++) csub(nx, ny)
   for (iy = 0; iy < ny; iy++)
      for (ix = 0; ix < nx; ix++)
         if (out[iy, ix] != inp[iy, ix] + ix + iy) {
            printf "Error: %s %d %d %s\n", out[iy, ix], ix, iy, inp[iy, ix]
            exit
         }
}
