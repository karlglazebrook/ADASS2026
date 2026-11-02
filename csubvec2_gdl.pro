; csubvec2_gdl.pro -- GDL whole-array form with the index arrays built on
; every call (2026), like numpy "arrays": ix = lindgen(nx,ny) mod nx and
; iy = lindgen(nx,ny) / nx, the standard IDL index-array idiom. Compare
; csubvec_gdl.pro, which precomputes the whole ix+iy matrix once outside
; the repeat loop so that only a single add is timed. Run as
;    gdl -quiet -e csubvec2_gdl -args 1000 2000 10

pro csubvec2_gdl
   args = command_line_args(count=nargs)
   nrpt = 1000L & nx = 2000L & ny = 10L
   if nargs ge 1 then nrpt = long(args[0])
   if nargs ge 2 then nx = long(args[1])
   if nargs ge 3 then ny = long(args[2])
   ina = (nx + ny) - (rebin(dindgen(nx), nx, ny) + rebin(transpose(dindgen(ny)), nx, ny))
   print, 'Arrays ', nx, ' by ', ny, ' count ', nrpt, format='(A,I0,A,I0,A,I0)'
   for irpt = 1L, nrpt do out = ina + (lindgen(nx, ny) mod nx) + (lindgen(nx, ny) / nx)
   for iy = 0L, ny-1 do begin
      for ix = 0L, nx-1 do begin
         if out[ix,iy] ne ina[ix,iy] + ix + iy then begin
            print, 'Error: ', out[ix,iy], ix, iy, ina[ix,iy]
            return
         endif
      endfor
   endfor
end
