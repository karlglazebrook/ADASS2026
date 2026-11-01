//  cjstestflat.js -- JavaScript with flat typed arrays (2026).
//
//  Keith's cjstest.js with one change of storage: each array is a single
//  Float64Array of ny*nx doubles, indexed iy*nx + ix, instead of an Array of
//  row Arrays. Typed arrays are contiguous, fixed-type buffers, the JS
//  counterpart of Swift's flat array (cstestflat.swift). Note Keith's arrays
//  hold whole numbers, which V8 keeps as small integers; these are doubles.
//  Runs unchanged in Node.js, Bun and Deno.

function subr(inp,nx,ny,out) {
   for (var iy = 0; iy < ny; iy++) {
      for (var ix = 0; ix < nx; ix++) {
         out[iy * nx + ix] = inp[iy * nx + ix] + ix + iy;
      }
   }
}

var nargs = process.argv.length;
var ny = 10;
var nx = 2000;
var nrpt = 1000;
if (nargs > 2) nrpt = parseInt(process.argv[2]);
if (nargs > 3) nx = parseInt(process.argv[3]);
if (nargs > 4) ny = parseInt(process.argv[4]);
console.log ("Arrays,",ny,"rows of",nx,"columns, repeat = ",nrpt);

var inp = new Float64Array(ny * nx);
var out = new Float64Array(ny * nx);
for (var iy = 0; iy < ny; iy++) {
   for (var ix = 0; ix < nx; ix++) {
      inp[iy * nx + ix] = nx - ix + ny - iy;
   }
}

for (var loop = 0; loop < nrpt; loop++) subr(inp,nx,ny,out);

TestLoop:
   for (var iy = 0; iy < ny; iy++) {
      for (var ix = 0; ix < nx; ix++) {
         if (out[iy * nx + ix] != (inp[iy * nx + ix] + ix + iy)) {
            console.log("Error:",out[iy * nx + ix],iy,ix,inp[iy * nx + ix]);
            break TestLoop;
         }
      }
   }
