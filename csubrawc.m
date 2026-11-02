% csubrawc.m -- Octave element loop, column-major layout (2026): the arrays
% are (nx, ny) with ix the first index, so the inner loop is unit-stride,
% as in Keith's Fortran, Julia and R versions. Otherwise csubraw.m, whose
% (ny, nx) layout walks the strided index inside. Twin of csubrawc_ml.m.
args = argv();
if length(args) >= 1, nrpt = str2double(args{1}); else nrpt = 100;  end
if length(args) >= 2, nx   = str2double(args{2}); else nx   = 2000; end
if length(args) >= 3, ny   = str2double(args{3}); else ny   = 10;   end
ina = zeros(nx, ny);
out = zeros(nx, ny);
for iy = 0:ny-1
   for ix = 0:nx-1
      ina(ix+1, iy+1) = nx - ix + ny - iy;
   end
end
printf('Arrays %d by %d count %d\n', nx, ny, nrpt);
for r = 1:nrpt
   for iy = 0:ny-1
      for ix = 0:nx-1
         out(ix+1, iy+1) = ina(ix+1, iy+1) + ix + iy;
      end
   end
end
err_found = false;
for iy = 0:ny-1
   for ix = 0:nx-1
      want = ina(ix+1, iy+1) + ix + iy;
      if abs(out(ix+1, iy+1) - want) > 1e-9
         printf('Error: %g %d %d %g\n', out(ix+1, iy+1), ix, iy, ina(ix+1, iy+1));
         err_found = true;
         break
      end
   end
   if err_found, break; end
end
