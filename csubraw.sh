#!/usr/bin/env bash
# csubraw.sh -- bash port (2026).
#
# bash has one-dimensional indexed arrays and integer-only arithmetic, so
# the arrays are flat (index iy*nx+ix) and hold integers. Keith's input
# values are whole numbers, so the results are the same; there is simply no
# floating point. Included as the far end of the scale: the shell everyone
# uses to drive everything else. Needs bash 4+ (brew bash), not macOS's 3.2.
#    bash csubraw.sh 3 2000 10

csub() {
   local ix iy k
   for ((iy = 0; iy < ny; iy++)); do
      for ((ix = 0; ix < nx; ix++)); do
         k=$((iy * nx + ix))
         out[k]=$((in[k] + ix + iy))
      done
   done
}

nrpt=${1:-3}
nx=${2:-2000}
ny=${3:-10}
in=()
out=()
for ((iy = 0; iy < ny; iy++)); do
   for ((ix = 0; ix < nx; ix++)); do
      in[iy * nx + ix]=$((nx - ix + ny - iy))
      out[iy * nx + ix]=0
   done
done
echo "Arrays $nx by $ny count $nrpt"
for ((r = 0; r < nrpt; r++)); do csub; done
for ((iy = 0; iy < ny; iy++)); do
   for ((ix = 0; ix < nx; ix++)); do
      k=$((iy * nx + ix))
      if (( out[k] != in[k] + ix + iy )); then
         echo "Error: ${out[k]} $ix $iy ${in[k]}"
         exit 0
      fi
   done
done
