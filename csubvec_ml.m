function csubvec_ml(nrpt, nx, ny)
% csubvec_ml.m -- MATLAB port of csubvec.m (2026): one whole-array
% expression with implicit expansion, out = in + ix_row + iy_col. Like
% csubvec.m, the index vectors are built in every repeat, as numpy and
% PDL "arrays" do (until 2 Nov 2026, once outside the timed loop). Run by bin/matlab-run; tic/toc printed as a cross-check.

if nargin < 1, nrpt = 1000; end
if nargin < 2, nx   = 2000; end
if nargin < 3, ny   = 10;   end

in  = zeros(ny, nx);
for iy = 0:ny-1
   in(iy+1, :) = (nx - (0:nx-1)) + ny - iy;
end

fprintf('Arrays %d by %d count %d\n', nx, ny, nrpt);

out = zeros(ny, nx);
t = tic;
for r = 1:nrpt
   out = in + (0:nx-1) + (0:ny-1)';
end
fprintf('Internal time %.4f s\n', toc(t));

for iy = 0:ny-1
   for ix = 0:nx-1
      if out(iy+1, ix+1) ~= in(iy+1, ix+1) + ix + iy
         fprintf('Error: %g %d %d %g\n', out(iy+1, ix+1), ix, iy, in(iy+1, ix+1));
         return
      end
   end
end
end
