function csubrawc_ml(nrpt, nx, ny)
% csubrawc_ml.m -- MATLAB element loop, column-major layout (2026): the
% arrays are (nx, ny) with ix the first index, so the inner loop is
% unit-stride, as in Keith's Fortran, Julia and R versions. Otherwise
% csubraw_ml.m, whose (ny, nx) layout walks the strided index inside.
% Run by bin/matlab-run as matlab -batch "csubrawc_ml(nrpt, nx, ny)".

if nargin < 1, nrpt = 100;  end
if nargin < 2, nx   = 2000; end
if nargin < 3, ny   = 10;   end

ina = zeros(nx, ny);
out = zeros(nx, ny);
for iy = 0:ny-1
   for ix = 0:nx-1
      ina(ix+1, iy+1) = nx - ix + ny - iy;
   end
end

fprintf('Arrays %d by %d count %d\n', nx, ny, nrpt);

t = tic;
for r = 1:nrpt
   for iy = 0:ny-1
      for ix = 0:nx-1
         out(ix+1, iy+1) = ina(ix+1, iy+1) + ix + iy;
      end
   end
end
fprintf('Internal time %.4f s\n', toc(t));

for iy = 0:ny-1
   for ix = 0:nx-1
      if out(ix+1, iy+1) ~= ina(ix+1, iy+1) + ix + iy
         fprintf('Error: %g %d %d %g\n', out(ix+1, iy+1), ix, iy, ina(ix+1, iy+1));
         return
      end
   end
end
end
