; csubraw_gdl.pro -- GDL (GNU Data Language, the open-source IDL) port of
; csubraw.m (2026): explicit element-by-element nested loops over 2D
; double arrays. IDL arrays are column-major with the first index fastest,
; so the element is a[ix,iy] and ix is the inner loop. Run as
;    gdl -quiet -e csubraw_gdl -args 100 2000 10
; (bin/gdl-run wraps that for Run.py). The code is plain IDL, so it should
; run unchanged in IDL itself.

pro csub_loop, ina, nx, ny, out
   for iy = 0L, ny-1 do begin
      for ix = 0L, nx-1 do begin
         out[ix,iy] = ina[ix,iy] + ix + iy
      endfor
   endfor
end

pro csubraw_gdl
   args = command_line_args(count=nargs)
   nrpt = 100L & nx = 2000L & ny = 10L
   if nargs ge 1 then nrpt = long(args[0])
   if nargs ge 2 then nx = long(args[1])
   if nargs ge 3 then ny = long(args[2])
   ina = dblarr(nx, ny)
   out = dblarr(nx, ny)
   for iy = 0L, ny-1 do for ix = 0L, nx-1 do ina[ix,iy] = nx - ix + ny - iy
   print, 'Arrays ', nx, ' by ', ny, ' count ', nrpt, format='(A,I0,A,I0,A,I0)'
   for irpt = 1L, nrpt do csub_loop, ina, nx, ny, out
   for iy = 0L, ny-1 do begin
      for ix = 0L, nx-1 do begin
         if out[ix,iy] ne ina[ix,iy] + ix + iy then begin
            print, 'Error: ', out[ix,iy], ix, iy, ina[ix,iy]
            return
         endif
      endfor
   endfor
end
