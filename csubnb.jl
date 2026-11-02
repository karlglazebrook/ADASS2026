# csubnb.jl -- Keith's csub.jl loop with @inbounds and Int64 indices (2026).
# csubint32nb.jl changes two things at once (bounds checks off, Int32
# counters); this variant changes only the first, to separate the two.
function subr!(in,nx,ny,out)
   for iy = 1:ny
      for ix = 1:nx
         @inbounds out[ix,iy] = in[ix,iy] + ix + iy
      end
   end
   return
end
nrpt = 100000
nx = 2000
ny = 10
if (length(ARGS) > 0); nrpt = parse(Int,ARGS[1]) end
if (length(ARGS) > 1); nx = parse(Int,ARGS[2]) end
if (length(ARGS) > 2); ny = parse(Int,ARGS[3]) end
println("Arrays have ",ny," rows of ",nx," columns, repeats = ",nrpt)
const in = zeros(Float32,nx,ny)
const out = zeros(Float32,nx,ny)
for iy = 1:ny, ix = 1:nx
   in[ix,iy] = nx - ix + ny - iy
end
for irpt = 1:nrpt
   subr!(in,nx,ny,out)
end
for iy = 1:ny, ix = 1:nx
   if out[ix,iy] != in[ix,iy] + ix + iy
      println("Error ",out[ix,iy]," ",ix," ",iy)
      break
   end
end
