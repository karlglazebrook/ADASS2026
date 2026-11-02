# csubptr.cr -- Crystal port, same Array(Slice(Float64)) layout as csubraw.cr,
# but the kernel walks each row through its raw Pointer (Slice#to_unsafe), so
# there is no per-element bounds check. (Crystal's --release keeps Slice#[]
# bounds checks; csubraw.cr's comment that it elides them is wrong.)
# Element loop, float64.
def subr(ina : Array(Slice(Float64)), nx : Int32, ny : Int32, outp : Array(Slice(Float64)))
  ny.times do |iy|
    pin = ina[iy].to_unsafe
    pout = outp[iy].to_unsafe
    fiy = iy.to_f64
    nx.times do |ix|
      pout[ix] = pin[ix] + ix.to_f64 + fiy
    end
  end
end

nrpt = (ARGV[0]? || "1000").to_i
nx   = (ARGV[1]? || "2000").to_i
ny   = (ARGV[2]? || "10").to_i
ina = Array.new(ny) { Slice(Float64).new(nx, 0.0) }
outp = Array.new(ny) { Slice(Float64).new(nx, 0.0) }
ny.times { |iy| nx.times { |ix| ina[iy][ix] = (nx - ix + ny - iy).to_f64 } }
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
