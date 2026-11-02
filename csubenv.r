# csubenv.r -- R "reference" variant using an environment (2026).
#
# Keith's csubref.r passes the output as a reference-class object and
# writes out$data[ix,iy] <- v for each element; R duplicates the whole
# matrix on every such store, so that test is O(nx*ny) per element.
# Here the output matrix lives in an environment (R's mutable reference
# type). The subroutine takes it out, fills it with plain local
# assignments (in place), and puts it back: one copy per call, not one
# per element. The caller sees the result through the same reference.

csub <- function(ina,nx,ny,env) {
   out <- env$data
   for (iy in 1:ny) {
      for (ix in 1:nx) {
         out[ix,iy] <- ina[ix,iy] + ix + iy
      }
   }
   env$data <- out
   invisible(NULL)
}

args <- commandArgs(TRUE)
nx = 2000
ny = 10
nrpt = 100
if (length(args) > 0) {
   nrpt = as.integer(args[1])
   if (length(args) > 1) {
      nx = as.integer(args[2])
      if (length(args) > 2) {
         ny = as.integer(args[3])
      }
   }
}
cat ("Arrays",nx,"by",ny,"repeat = ",nrpt,"\n")
ina <- matrix(0.0,nx,ny)
for (iy in 1:ny) {
   for (ix in 1:nx) {
      ina[ix,iy] = nx - ix + ny - iy
   }
}
env <- new.env()
env$data <- matrix(0.0,nx,ny)
for (irpt in 1:nrpt) {
   csub(ina,nx,ny,env)
}
error = FALSE
for (iy in 1:ny) {
   for (ix in 1:nx) {
      if (env$data[ix,iy] != ina[ix,iy] + ix + iy) {
         cat("Error",ix,iy,ina[ix,iy],env$data[ix,iy],"\n")
         error = TRUE
         break
      }
   }
   if (error) { break }
}
