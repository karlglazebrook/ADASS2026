#  csubbcast.jl -- Julia dot-broadcast (2026).
#
#  Keith's csub.jl with the loop replaced by one broadcast expression:
#  in place of the nested for loops, out .= in .+ (1:nx) .+ (1:ny)'. The
#  ranges are lazy, so nothing is allocated per call; Julia fuses the whole
#  expression into a single loop. Float32 arrays, as in csub.jl.

function subr!(in,nx,ny,out)
   out .= in .+ (1:nx) .+ (1:ny)'
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
      println("error ",out[ix,iy]," ",ix," ",iy)
      break
   end
end
