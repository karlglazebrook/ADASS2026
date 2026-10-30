## csubraw.nim - Nim port of csubraw.py / csubraw.cr.
##
## Nim is Python-syntax that compiles to C via gcc/clang.  --gc:arc and
## -d:danger together produce code with no GC overhead and no runtime
## checks (similar to D's -release).
##
## Build:
##   nim c -d:danger --gc:arc -o:csub_nim csubraw.nim

import os, strutils

proc subr(inp: var seq[seq[float64]]; nx, ny: int;
          outp: var seq[seq[float64]]) =
   for iy in 0 ..< ny:
      let fiy = float64(iy)
      for ix in 0 ..< nx:
         outp[iy][ix] = inp[iy][ix] + float64(ix) + fiy

proc main() =
   let args = commandLineParams()
   let nrpt = if args.len > 0: parseInt(args[0]) else: 1000
   let nx   = if args.len > 1: parseInt(args[1]) else: 2000
   let ny   = if args.len > 2: parseInt(args[2]) else: 10

   var inp  = newSeq[seq[float64]](ny)
   var outp = newSeq[seq[float64]](ny)
   for iy in 0 ..< ny:
      inp[iy]  = newSeq[float64](nx)
      outp[iy] = newSeq[float64](nx)
      for ix in 0 ..< nx:
         inp[iy][ix] = float64(nx - ix + ny - iy)

   echo "Arrays ", nx, " by ", ny, " count ", nrpt

   for r in 0 ..< nrpt:
      subr(inp, nx, ny, outp)

   for iy in 0 ..< ny:
      for ix in 0 ..< nx:
         let want = inp[iy][ix] + float64(ix) + float64(iy)
         if outp[iy][ix] != want:
            echo "Error: ", outp[iy][ix], " ", ix, " ", iy, " ", inp[iy][ix]
            return

main()
