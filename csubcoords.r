# csubcoords.r -- R whole-array form with recycled coordinate vectors
# (2026, from the ChatGPT review). Zero-based coordinate vectors x (length
# nx) and yfull (length nx*ny, the column index repeated) are built once;
# each repeat does the two input-dependent additions (ina + x) + yfull.
# Compare csubouter.r (outer() per call) and csubrecyc.r (rep() per call).
a <- as.integer(commandArgs(TRUE))
nrpt <- if (length(a) >= 1) a[1] else 1000L
nx <- if (length(a) >= 2) a[2] else 2000L
ny <- if (length(a) >= 3) a[3] else 10L
stopifnot(nrpt > 0L, nx > 0L, ny > 0L)
cat ("Arrays",nx,"by",ny,"repeat = ",nrpt,"\n")
x <- as.double(seq_len(nx) - 1L)
y <- as.double(seq_len(ny) - 1L)
yfull <- rep(y, each=nx)
ina <- matrix(nx + ny, nx, ny) - x - yfull
for (r in seq_len(nrpt)) out <- (ina + x) + yfull
for (iy in seq_len(ny)) for (ix in seq_len(nx)) {
    if (!isTRUE(out[ix,iy] == (ina[ix,iy] + x[ix]) + y[iy]))
        stop("Error: result mismatch")
}
