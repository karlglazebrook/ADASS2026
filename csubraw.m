% csubraw.m -- Octave port: explicit element-by-element nested loops.
%
% This exercises Octave's interpreter on the Python-list-style idiom.
% Compare against csubvec.m which uses Octave's native vectorised
% broadcasting (the BLAS-fast path).

args = argv();
if length(args) >= 1, nrpt = str2num(args{1}); else nrpt = 100;  end
if length(args) >= 2, nx   = str2num(args{2}); else nx   = 2000; end
if length(args) >= 3, ny   = str2num(args{3}); else ny   = 10;   end

ina = zeros(ny, nx);
out = zeros(ny, nx);
for iy = 0:ny-1
   for ix = 0:nx-1
      ina(iy+1, ix+1) = nx - ix + ny - iy;
   end
end

printf('Arrays %d by %d count %d\n', nx, ny, nrpt);

for r = 1:nrpt
   for iy = 0:ny-1
      for ix = 0:nx-1
         out(iy+1, ix+1) = ina(iy+1, ix+1) + ix + iy;
      end
   end
end

err_found = false;
for iy = 0:ny-1
   for ix = 0:nx-1
      want = ina(iy+1, ix+1) + ix + iy;
      if abs(out(iy+1, ix+1) - want) > 1e-9
         printf('Error: %g %d %d %g\n', out(iy+1, ix+1), ix, iy, ina(iy+1, ix+1));
         err_found = true;
         break
      end
   end
   if err_found, break; end
end
