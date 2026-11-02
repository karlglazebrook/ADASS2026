#!/usr/bin/env bash
# csubarith.sh -- csubraw.sh in arithmetic-command form (2026 review variant).
# Integer-attribute arrays (declare -ai) so reads need no string-to-integer
# conversion; the element store is done inside (( )) rather than through a
# $(( )) word expansion; the flat index is a running counter.  Still integer
# only, like csubraw.sh.
csub() {
   local -i ix iy k=0
   for ((iy = 0; iy < ny; iy++)); do
      for ((ix = 0; ix < nx; ix++, k++)); do
         (( out[k] = in[k] + ix + iy ))
      done
   done
}

nrpt=${1:-3}
nx=${2:-2000}
ny=${3:-10}
declare -ai in=() out=()
for ((iy = 0; iy < ny; iy++)); do
   for ((ix = 0; ix < nx; ix++)); do
      (( in[iy * nx + ix] = nx - ix + ny - iy, out[iy * nx + ix] = 0 ))
   done
done
echo "Arrays $nx by $ny count $nrpt"
for ((r = 0; r < nrpt; r++)); do csub; done
for ((iy = 0; iy < ny; iy++)); do
   for ((ix = 0; ix < nx; ix++)); do
      k=$((iy * nx + ix))
      if (( out[k] != in[k] + ix + iy )); then
         echo "Error: ${out[k]} $ix $iy ${in[k]}"
         exit 1
      fi
   done
done
