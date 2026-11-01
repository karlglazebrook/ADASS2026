function csubraw_ml(nrpt, nx, ny)
% csubraw_ml.m -- MATLAB port of csubraw.m (2026): the same explicit
% element-by-element nested loops, as a function because MATLAB scripts
% cannot take command-line arguments. Run by bin/matlab-run, which calls
%    matlab -batch "csubraw_ml(nrpt, nx, ny)"
% MATLAB has JIT-compiled such loops since its R2015b execution engine;
% Octave has no JIT, so this pair isolates the runtime on identical code.
% The internal tic/toc time is printed as a cross-check on Run.py's
% wall-clock timing, which includes MATLAB's ~13 s startup.

if nargin < 1, nrpt = 100;  end
if nargin < 2, nx   = 2000; end
if nargin < 3, ny   = 10;   end

ina = zeros(ny, nx);
out = zeros(ny, nx);
for iy = 0:ny-1
   for ix = 0:nx-1
      ina(iy+1, ix+1) = nx - ix + ny - iy;
   end
end

fprintf('Arrays %d by %d count %d\n', nx, ny, nrpt);

t = tic;
for r = 1:nrpt
   for iy = 0:ny-1
      for ix = 0:nx-1
         out(iy+1, ix+1) = ina(iy+1, ix+1) + ix + iy;
      end
   end
end
fprintf('Internal time %.4f s\n', toc(t));

for iy = 0:ny-1
   for ix = 0:nx-1
      if out(iy+1, ix+1) ~= ina(iy+1, ix+1) + ix + iy
         fprintf('Error: %g %d %d %g\n', out(iy+1, ix+1), ix, iy, ina(iy+1, ix+1));
         return
      end
   end
end
end
