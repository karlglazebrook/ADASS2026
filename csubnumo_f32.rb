#!/usr/bin/env ruby
#
#  2026 review variant: csubnumo.rb with Numo::SFloat (32-bit) arrays
#  instead of Numo::DFloat; otherwise identical.
#                              c s u b n u m o _ f 3 2 . r b
#
#  Summary:
#     2D array access test in Ruby, using Numo::NArray (Ruby's numpy).
#
#  Introduction:
#     Mirror of csubnpna.py.  Numo::NArray is the Ruby ecosystem's standard
#     numerical array library, modelled directly on numpy: it stores
#     contiguous typed arrays in C with broadcasting semantics, and ships
#     element-wise operators backed by C.  The whole 2D-array-plus-indices
#     operation can be written in one broadcast-driven line, exactly like
#     the numpy "arrays" version.
#
#  Invocation:
#     ruby csubnumo.rb irpt nx ny
#       irpt  number of subroutine calls (default 10000)
#       nx    columns (default 2000)
#       ny    rows    (default 10)
#

require 'numo/narray'
DF = Numo::SFloat

#  --------------------------------------------------------------------------
#
#  This subr() is the equivalent of:
#     for iy in 0...ny do
#        for ix in 0...nx do
#           out[iy, ix] = ina[iy, ix] + ix + iy
#        end
#     end
#  but uses Numo::NArray broadcasting to do it in one line.  arange via .seq
#  produces a 1-D Numo array; the .reshape(1, nx) and .reshape(ny, 1) calls
#  give the broadcast shapes that yield the matrix of (ix + iy) values when
#  added.  inplace assignment via out[] = ... avoids reallocating output.

def subr(ina, nx, ny, out)
   out[true, true] = ina + DF.new(nx).seq.reshape(1, nx) +
                           DF.new(ny).seq.reshape(ny, 1)
end

#  --------------------------------------------------------------------------

ny   = 10
nx   = 2000
nrpt = 10000
nrpt = ARGV[0].to_i if ARGV.length > 0
nx   = ARGV[1].to_i if ARGV.length > 1
ny   = ARGV[2].to_i if ARGV.length > 2

#  Build input the same way the numpy version does — descending sum of
#  indices.  We do it via broadcasting too, so initialisation isn't itself
#  the bottleneck.  Note: don't use .inplace here — the flag is persistent
#  and would cause subsequent ops on ina (inside subr) to mutate it.
ix_row = DF.new(nx).seq.reshape(1, nx)
iy_col = DF.new(ny).seq.reshape(ny, 1)
ina = DF.new(ny, nx).fill(nx + ny) - ix_row - iy_col
out = DF.zeros(ny, nx)

puts "Arrays #{nx} by #{ny} count #{nrpt}"

nrpt.times { subr(ina, nx, ny, out) }

#  Check the results — single broadcast, then look for any non-zero diff.
expected = ina + DF.new(nx).seq.reshape(1, nx) +
                 DF.new(ny).seq.reshape(ny, 1)
diff = (out - expected).abs.max
if diff > 0
   #  Find first mismatch for the diagnostic.
   ny.times do |iy|
      nx.times do |ix|
         if out[iy, ix] != ina[iy, ix] + ix + iy
            puts "Error: #{out[iy, ix]} #{ix} #{iy} #{ina[iy, ix]}"
            exit 1
         end
      end
   end
end
