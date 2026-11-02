; csubsingle_gdl.pro -- GDL whole-array form, single precision, with two
; separate coordinate planes (2026, from the ChatGPT review): xx and yy are
; built once, and each repeat does the two additions (ina + xx) + yy, so
; the ix+iy sum is not precomputed. One thread via cpu, tpool_nthreads=1.
; Run as
;    gdl -quiet -e csubsingle_gdl -args 1000 2000 10

pro csubsingle_gdl
  cpu, tpool_nthreads=1
  args=command_line_args(count=nargs)
  nrpt=1000L & nx=2000L & ny=10L
  if nargs ge 1 then nrpt=long(args[0])
  if nargs ge 2 then nx=long(args[1])
  if nargs ge 3 then ny=long(args[2])
  if nrpt le 0 or nx le 0 or ny le 0 then message, 'positive dimensions required'
  xx=rebin(findgen(nx),nx,ny)
  yy=rebin(transpose(findgen(ny)),nx,ny)
  ina=float(nx+ny)-xx-yy
  print, 'Arrays ', nx, ' by ', ny, ' count ', nrpt, format='(A,I0,A,I0,A,I0)'
  for r=1L,nrpt do out=(ina+xx)+yy
  for y=0L,ny-1 do begin
    for x=0L,nx-1 do begin
      if out[x,y] ne (ina[x,y]+float(x))+float(y) then message, 'Error: mismatch'
    endfor
  endfor
end
