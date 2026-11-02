# csubmain32.jl -- Keith's int32 @inbounds kernel (csubint32nb.jl) with the
# driver in a function (2026), so nx, ny, in and out are typed locals and
# the repeat loop makes a static call instead of a dynamic dispatch on
# untyped globals (nx, ny are non-const globals in Keith's scripts).
function subr!(in,nx,ny,out)
   for iy = Int32(1):Int32(ny)
      for ix = Int32(1):Int32(nx)
         @inbounds out[ix,iy] = in[ix,iy] + ix + iy
      end
   end
   return
end
function main(args)
   nrpt = 100000; nx = 2000; ny = 10
   length(args) > 0 && (nrpt = parse(Int,args[1]))
   length(args) > 1 && (nx = parse(Int,args[2]))
   length(args) > 2 && (ny = parse(Int,args[3]))
   println("Arrays have ",ny," rows of ",nx," columns, repeats = ",nrpt)
   in = zeros(Float32,nx,ny); out = zeros(Float32,nx,ny)
   for iy = 1:ny, ix = 1:nx
      in[ix,iy] = nx - ix + ny - iy
   end
   for irpt = 1:nrpt
      subr!(in,nx,ny,out)
   end
   for iy = 1:ny, ix = 1:nx
      if out[ix,iy] != in[ix,iy] + ix + iy
         println("Error ",out[ix,iy]," ",ix," ",iy); break
      end
   end
end
main(ARGS)
