#!/usr/bin/env ruby
# csubwhile.rb -- csubraw.rb with while loops (2026 review variant).
# Integer#times yields to a block per element; in the CRuby interpreter a
# while loop avoids the block call and is the form Ruby benchmarks use for
# hot loops.  Same Array of Arrays of Float as csubraw.rb.

def subr(ina, nx, ny, out)
   iy = 0
   while iy < ny
      row_in  = ina[iy]
      row_out = out[iy]
      ix = 0
      while ix < nx
         row_out[ix] = row_in[ix] + ix + iy
         ix += 1
      end
      iy += 1
   end
end

ny   = 10
nx   = 2000
nrpt = 100
nrpt = ARGV[0].to_i if ARGV.length > 0
nx   = ARGV[1].to_i if ARGV.length > 1
ny   = ARGV[2].to_i if ARGV.length > 2

ina = Array.new(ny) { Array.new(nx, 0.0) }
out = Array.new(ny) { Array.new(nx, 0.0) }
ny.times { |iy| nx.times { |ix| ina[iy][ix] = (nx - ix + ny - iy).to_f } }

puts "Arrays #{nx} by #{ny} count #{nrpt}"

nrpt.times { subr(ina, nx, ny, out) }

catch(:done) do
   ny.times do |iy|
      nx.times do |ix|
         if out[iy][ix] != ina[iy][ix] + ix + iy
            puts "Error: #{out[iy][ix]} #{ix} #{iy} #{ina[iy][ix]}"
            throw :done
         end
      end
   end
end
