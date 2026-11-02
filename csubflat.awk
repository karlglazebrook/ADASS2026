# csubflat.awk -- awk with a flat numeric index (2026 review variant of
# csubraw.awk).  inp[iy, ix] builds the string key  iy SUBSEP ix  on every
# access (two number-to-string conversions and a concatenation); a single
# integer key iy*nx+ix takes the integer-key fast path in both mawk and gawk.
# Works in any awk.
function csub(nx, ny,    ix, iy, k) {
   for (iy = 0; iy < ny; iy++) {
      k = iy * nx
      for (ix = 0; ix < nx; ix++)
         out[k + ix] = inp[k + ix] + ix + iy
   }
}

BEGIN {
   nrpt = (ARGC > 1) ? ARGV[1] + 0 : 100
   nx = (ARGC > 2) ? ARGV[2] + 0 : 2000
   ny = (ARGC > 3) ? ARGV[3] + 0 : 10
   for (iy = 0; iy < ny; iy++)
      for (ix = 0; ix < nx; ix++) {
         inp[iy * nx + ix] = nx - ix + ny - iy
         out[iy * nx + ix] = 0.0
      }
   printf "Arrays %d by %d count %d\n", nx, ny, nrpt
   for (r = 0; r < nrpt; r++) csub(nx, ny)
   for (iy = 0; iy < ny; iy++)
      for (ix = 0; ix < nx; ix++)
         if (out[iy * nx + ix] != inp[iy * nx + ix] + ix + iy) {
            printf "Error: %s %d %d %s\n", out[iy * nx + ix], ix, iy, inp[iy * nx + ix]
            exit
         }
}
