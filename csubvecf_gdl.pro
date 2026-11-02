; csubvecf_gdl.pro -- single-precision (float32) twin of csubvec_gdl.pro
; (2026): findgen/float instead of dindgen/double, otherwise identical,
; including the ix+iy matrix precomputed once outside the repeat loop.
; Run as
;    gdl -quiet -e csubvecf_gdl -args 1000 2000 10

pro csubvecf_gdl
   args = command_line_args(count=nargs)
   nrpt = 1000L & nx = 2000L & ny = 10L
   if nargs ge 1 then nrpt = long(args[0])
   if nargs ge 2 then nx = long(args[1])
   if nargs ge 3 then ny = long(args[2])
   ixy = rebin(findgen(nx), nx, ny) + rebin(transpose(findgen(ny)), nx, ny)
   ina = float(nx + ny) - ixy
   print, 'Arrays ', nx, ' by ', ny, ' count ', nrpt, format='(A,I0,A,I0,A,I0)'
   for irpt = 1L, nrpt do out = ina + ixy
   for iy = 0L, ny-1 do begin
      for ix = 0L, nx-1 do begin
         if out[ix,iy] ne ina[ix,iy] + ix + iy then begin
            print, 'Error: ', out[ix,iy], ix, iy, ina[ix,iy]
            return
         endif
      endfor
   endfor
end
