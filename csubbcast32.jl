# csubbcast32.jl -- Julia dot-broadcast with Int32 index ranges (2026).
# Keith's csubbcast.jl with (1:nx) and (1:ny) replaced by Int32 ranges, so
# the fused loop converts four int32 lanes per NEON vector into Float32
# instead of two int64 lanes. No allocation; same expression otherwise.
function subr!(in,nx,ny,out)
   out .= in .+ (Int32(1):Int32(nx)) .+ (Int32(1):Int32(ny))'
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
