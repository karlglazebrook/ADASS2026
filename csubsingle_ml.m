function csubsingle_ml(nrpt,nx,ny)
% csubsingle_ml.m -- MATLAB element loop, (nx,ny) layout, single precision,
% one computational thread (2026, from the ChatGPT review). Zero-based
% coordinates are added as single scalars. Run by bin/matlab-run.
if nargin<1, nrpt=1000; end
if nargin<2, nx=2000; end
if nargin<3, ny=10; end
assert(nrpt>0 && nx>0 && ny>0);
old=maxNumCompThreads(1);
restore=onCleanup(@() maxNumCompThreads(old));
a=zeros(nx,ny,'single'); b=a;
for y=0:ny-1
    for x=0:nx-1
        a(x+1,y+1)=single(nx-x+ny-y);
    end
end
fprintf('Arrays %d by %d count %d\n', nx, ny, nrpt);
t = tic;
for r=1:nrpt
    for y=0:ny-1
        for x=0:nx-1
            b(x+1,y+1)=(a(x+1,y+1)+single(x))+single(y);
        end
    end
end
fprintf('Internal time %.4f s\n', toc(t));
for y=0:ny-1
    for x=0:nx-1
        if b(x+1,y+1) ~= (a(x+1,y+1)+single(x))+single(y)
            error('Error: result mismatch');
        end
    end
end
end
