## csubraw32.nim - csubraw.nim in float32 (2026 review variant).
##
## Same seq[seq[...]] layout and per-element double indexing as csubraw.nim,
## with float32 elements and a read-only input parameter.
##
##   nim c -d:danger --mm:arc -o:csub_nim32 csubraw32.nim

import os, strutils

proc subr(inp: seq[seq[float32]]; nx, ny: int;
          outp: var seq[seq[float32]]) =
   for iy in 0 ..< ny:
      let fiy = float32(iy)
      for ix in 0 ..< nx:
         outp[iy][ix] = inp[iy][ix] + float32(ix) + fiy

proc main() =
   let args = commandLineParams()
   let nrpt = if args.len > 0: parseInt(args[0]) else: 1000
   let nx   = if args.len > 1: parseInt(args[1]) else: 2000
   let ny   = if args.len > 2: parseInt(args[2]) else: 10

   var inp  = newSeq[seq[float32]](ny)
   var outp = newSeq[seq[float32]](ny)
   for iy in 0 ..< ny:
      inp[iy]  = newSeq[float32](nx)
      outp[iy] = newSeq[float32](nx)
      for ix in 0 ..< nx:
         inp[iy][ix] = float32(nx - ix + ny - iy)

   echo "Arrays ", nx, " by ", ny, " count ", nrpt

   for r in 0 ..< nrpt:
      subr(inp, nx, ny, outp)

   for iy in 0 ..< ny:
      for ix in 0 ..< nx:
         let want = inp[iy][ix] + float32(ix) + float32(iy)
         if outp[iy][ix] != want:
            echo "Error: ", outp[iy][ix], " ", ix, " ", iy, " ", inp[iy][ix]
            quit(1)

main()
