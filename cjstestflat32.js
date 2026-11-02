//  cjstestflat32.js -- cjstestflat.js with Float32Array (float32) (2026).
//  Same flat layout; 32-bit elements. JS arithmetic is double, so each
//  element is widened on load and rounded on store.
function subr(inp,nx,ny,out) {
   for (var iy = 0; iy < ny; iy++) {
      var base = iy * nx;
      for (var ix = 0; ix < nx; ix++) {
         out[base + ix] = inp[base + ix] + ix + iy;
      }
   }
}
var nargs = process.argv.length;
var ny = 10, nx = 2000, nrpt = 1000;
if (nargs > 2) nrpt = parseInt(process.argv[2]);
if (nargs > 3) nx = parseInt(process.argv[3]);
if (nargs > 4) ny = parseInt(process.argv[4]);
console.log ("Arrays,",ny,"rows of",nx,"columns, repeat = ",nrpt);
var inp = new Float32Array(ny * nx), out = new Float32Array(ny * nx);
for (var iy = 0; iy < ny; iy++)
   for (var ix = 0; ix < nx; ix++) inp[iy * nx + ix] = nx - ix + ny - iy;
for (var loop = 0; loop < nrpt; loop++) subr(inp,nx,ny,out);
TestLoop:
   for (var iy = 0; iy < ny; iy++)
      for (var ix = 0; ix < nx; ix++)
         if (out[iy * nx + ix] != Math.fround(inp[iy * nx + ix] + ix + iy)) {
            console.log("Error:",out[iy * nx + ix],iy,ix,inp[iy * nx + ix]); break TestLoop;
         }
