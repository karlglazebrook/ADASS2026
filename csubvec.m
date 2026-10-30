% csubvec.m -- Octave vectorised version of csubraw.m.
%
% Vector-language idiom: the inner kernel is one expression that adds
% two index vectors broadcast across the array.  This is what an
% Octave/Matlab programmer would actually write.

args = argv();
if length(args) >= 1, nrpt = str2num(args{1}); else nrpt = 1000; end
if length(args) >= 2, nx   = str2num(args{2}); else nx   = 2000; end
if length(args) >= 3, ny   = str2num(args{3}); else ny   = 10;   end

in  = zeros(ny, nx);
out = zeros(ny, nx);
for iy = 0:ny-1
   in(iy+1, :) = (nx - (0:nx-1)) + ny - iy;
end

printf('Arrays %d by %d count %d\n', nx, ny, nrpt);

ix_row = 0:nx-1;
iy_col = (0:ny-1)';

for r = 1:nrpt
   out = in + ix_row + iy_col;
end

err_found = false;
for iy = 0:ny-1
   for ix = 0:nx-1
      want = in(iy+1, ix+1) + ix + iy;
      if abs(out(iy+1, ix+1) - want) > 1e-9
         printf('Error: %g %d %d %g\n', out(iy+1, ix+1), ix, iy, in(iy+1, ix+1));
         err_found = true;
         break
      end
   end
   if err_found, break; end
end
