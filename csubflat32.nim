## csubflat32.nim -- csubflat.nim in float32 (2026 review variant).
## the kernel taking openArray views, the idiomatic way to pass a buffer in
## Nim. Element loop, float32.
##   nim c -d:danger --mm:arc -o:csubflat csubflat.nim ; ./csubflat 1000 2000 10
import os, strutils

proc subr(inp: openArray[float32]; nx, ny: int; outp: var openArray[float32]) =
   for iy in 0 ..< ny:
      let base = iy * nx
      let fiy = float32(iy)
      for ix in 0 ..< nx:
         outp[base + ix] = inp[base + ix] + float32(ix) + fiy

proc main() =
   let args = commandLineParams()
   let nrpt = if args.len > 0: parseInt(args[0]) else: 1000
   let nx   = if args.len > 1: parseInt(args[1]) else: 2000
   let ny   = if args.len > 2: parseInt(args[2]) else: 10
   var inp  = newSeq[float32](nx * ny)
   var outp = newSeq[float32](nx * ny)
   for iy in 0 ..< ny:
      for ix in 0 ..< nx:
         inp[iy * nx + ix] = float32(nx - ix + ny - iy)
   echo "Arrays ", nx, " by ", ny, " count ", nrpt
   for r in 0 ..< nrpt:
      subr(inp, nx, ny, outp)
   for iy in 0 ..< ny:
      for ix in 0 ..< nx:
         let want = inp[iy * nx + ix] + float32(ix) + float32(iy)
         if outp[iy * nx + ix] != want:
            echo "Error: ", outp[iy * nx + ix], " ", ix, " ", iy, " ", inp[iy * nx + ix]
            return
main()
