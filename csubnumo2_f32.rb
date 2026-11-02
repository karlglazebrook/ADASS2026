#!/usr/bin/env ruby
# csubnumo2_f32.rb -- float32 Numo::NArray whole-array variant without temporaries
# (2026 review variant of csubnumo.rb).  csubnumo.rb forms two ny*nx
# temporaries and then copies them through out[true,true]=, which goes
# through Numo's index-parsing path.  Here out.store copies the input and
# the two index vectors are added in place with the inplace flag, which
# Numo sets on a lightweight view, not on `out` itself.
require 'numo/narray'
DF = Numo::SFloat

def subr(ina, nx, ny, out)
   out.store(ina)
   out.inplace + DF.new(nx).seq.reshape(1, nx)
   out.inplace + DF.new(ny).seq.reshape(ny, 1)
end

ny   = 10
nx   = 2000
nrpt = 10000
nrpt = ARGV[0].to_i if ARGV.length > 0
nx   = ARGV[1].to_i if ARGV.length > 1
ny   = ARGV[2].to_i if ARGV.length > 2

ix_row = DF.new(nx).seq.reshape(1, nx)
iy_col = DF.new(ny).seq.reshape(ny, 1)
ina = DF.new(ny, nx).fill(nx + ny) - ix_row - iy_col
out = DF.zeros(ny, nx)

puts "Arrays #{nx} by #{ny} count #{nrpt}"

nrpt.times { subr(ina, nx, ny, out) }

expected = ina + ix_row + iy_col
diff = (out - expected).abs.max
if diff > 0
   ny.times do |iy|
      nx.times do |ix|
         if out[iy, ix] != ina[iy, ix] + ix + iy
            puts "Error: #{out[iy, ix]} #{ix} #{iy} #{ina[iy, ix]}"
            exit 1
         end
      end
   end
end
