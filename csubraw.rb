#!/usr/bin/env ruby
#
#                              c s u b r a w . r b
#
#  Summary:
#     2D array access test in Ruby, using arrays of arrays.
#
#  Introduction:
#     This is a Ruby port of csubraw.py, written for the same study into how
#     well different languages handle accessing elements of 2D rectangular
#     arrays.  Each element of an Nx by Ny float array is set to the
#     corresponding element of an input array plus the sum of its two indices.
#
#  This version:
#     The 'array' is an Array of Arrays of Float, accessed via the standard
#     out[iy][ix] = ... idiom.  This mirrors the csubraw.py "lists of lists"
#     test exactly so the timings can be compared head-to-head.
#
#  Invocation:
#     ruby csubraw.rb irpt nx ny
#       irpt  number of subroutine calls (default 100)
#       nx    columns (default 2000)
#       ny    rows    (default 10)
#

def subr(ina, nx, ny, out)
   ny.times do |iy|
      row_in  = ina[iy]
      row_out = out[iy]
      nx.times do |ix|
         row_out[ix] = row_in[ix] + ix + iy
      end
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

#  Check the results.
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
