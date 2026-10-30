# csubraw.cr — Crystal port of csubraw.py / csubraw.rb.
#
# Crystal has Ruby-style syntax but is statically typed, AOT-compiled to
# native via LLVM, and has no GC overhead per allocation in tight loops.
# Use Slice(Float64) for the inner row so element access lowers to a
# straight load with no bounds checks (crystal --release elides them).

def subr(ina : Array(Slice(Float64)), nx : Int32, ny : Int32, outp : Array(Slice(Float64)))
   ny.times do |iy|
      row_in = ina[iy]
      row_outp = outp[iy]
      nx.times do |ix|
         row_outp[ix] = row_in[ix] + ix.to_f64 + iy.to_f64
      end
   end
end

nrpt = (ARGV[0]? || "1000").to_i
nx   = (ARGV[1]? || "2000").to_i
ny   = (ARGV[2]? || "10").to_i

ina = Array.new(ny) { Slice(Float64).new(nx, 0.0) }
outp = Array.new(ny) { Slice(Float64).new(nx, 0.0) }
ny.times do |iy|
   nx.times do |ix|
      ina[iy][ix] = (nx - ix + ny - iy).to_f64
   end
end

puts "Arrays #{nx} by #{ny} count #{nrpt}"

nrpt.times { subr(ina, nx, ny, outp) }

ny.times do |iy|
   nx.times do |ix|
      if outp[iy][ix] != ina[iy][ix] + ix + iy
         puts "Error: #{outp[iy][ix]} #{ix} #{iy} #{ina[iy][ix]}"
         exit 1
      end
   end
end
