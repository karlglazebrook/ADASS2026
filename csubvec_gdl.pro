; csubvec_gdl.pro -- GDL port of csubvec.m (2026): one whole-array
; expression, out = ina + ixy, where ixy holds ix + iy for every element,
; built with the usual IDL rebin idiom. The index arrays are rebuilt in
; every repeat, as numpy, PDL and Numo do; until 2 Nov 2026 they were built
; once outside the timed loop, which left one add per repeat. Run as
;    gdl -quiet -e csubvec_gdl -args 1000 2000 10

pro csubvec_gdl
   args = command_line_args(count=nargs)
   nrpt = 1000L & nx = 2000L & ny = 10L
   if nargs ge 1 then nrpt = long(args[0])
   if nargs ge 2 then nx = long(args[1])
   if nargs ge 3 then ny = long(args[2])
   ina = (nx + ny) - (rebin(dindgen(nx), nx, ny) + rebin(transpose(dindgen(ny)), nx, ny))
   print, 'Arrays ', nx, ' by ', ny, ' count ', nrpt, format='(A,I0,A,I0,A,I0)'
   for irpt = 1L, nrpt do out = ina + rebin(dindgen(nx), nx, ny) + rebin(transpose(dindgen(ny)), nx, ny)
   for iy = 0L, ny-1 do begin
      for ix = 0L, nx-1 do begin
         if out[ix,iy] ne ina[ix,iy] + ix + iy then begin
            print, 'Error: ', out[ix,iy], ix, iy, ina[ix,iy]
            return
         endif
      endfor
   endfor
end
