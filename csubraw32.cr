# csubraw32.cr -- Crystal port in Float32 (2026 review variant).
#
# csubraw.cr with Slice(Float32) rows, the precision of Keith's C kernel.
# (Note: crystal --release does not remove Slice#[] bounds checks; LLVM hoists
# them out of the inner loop here.)

def subr(ina : Array(Slice(Float32)), nx : Int32, ny : Int32, outp : Array(Slice(Float32)))
   ny.times do |iy|
      row_in = ina[iy]
      row_outp = outp[iy]
      fiy = iy.to_f32
      nx.times do |ix|
         row_outp[ix] = row_in[ix] + ix.to_f32 + fiy
      end
   end
end

nrpt = (ARGV[0]? || "1000").to_i
nx   = (ARGV[1]? || "2000").to_i
ny   = (ARGV[2]? || "10").to_i

ina = Array.new(ny) { Slice(Float32).new(nx, 0.0_f32) }
outp = Array.new(ny) { Slice(Float32).new(nx, 0.0_f32) }
ny.times do |iy|
   nx.times do |ix|
      ina[iy][ix] = (nx - ix + ny - iy).to_f32
   end
end

puts "Arrays #{nx} by #{ny} count #{nrpt}"

nrpt.times { subr(ina, nx, ny, outp) }

ny.times do |iy|
   nx.times do |ix|
      if outp[iy][ix] != ina[iy][ix] + ix.to_f32 + iy.to_f32
         puts "Error: #{outp[iy][ix]} #{ix} #{iy} #{ina[iy][ix]}"
         exit 1
      end
   end
end
