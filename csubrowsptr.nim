## csubrowsptr.nim -- Nim port, seq[seq[float64]] layout as csubraw.nim; the
## kernel takes the address of each row once and walks it as
## ptr UncheckedArray, the usual Nim idiom for a hot inner loop. The seq
## headers are then not re-read on every element, which is what stops clang
## vectorising csubraw.nim's loop. Element loop, float64.
##   nim c -d:danger --mm:arc -o:csubrowsptr csubrowsptr.nim ; ./csubrowsptr 1000 2000 10
import os, strutils

proc subr(inp: seq[seq[float64]]; nx, ny: int; outp: var seq[seq[float64]]) =
   for iy in 0 ..< ny:
      let rowIn  = cast[ptr UncheckedArray[float64]](inp[iy][0].unsafeAddr)
      let rowOut = cast[ptr UncheckedArray[float64]](outp[iy][0].addr)
      let fiy = float64(iy)
      for ix in 0 ..< nx:
         rowOut[ix] = rowIn[ix] + float64(ix) + fiy
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
