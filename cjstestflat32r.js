//  cjstestflat32r.js -- flat Float32Array with explicit float32 arithmetic (2026).
//
//  cjstestflat32.js stores float32 but computes in double (JS Number).
//  This variant, proposed in the ChatGPT review, also rounds every
//  intermediate with Math.fround, so the arithmetic itself is binary32,
//  as in Keith's C and Java float kernels. Runs in Node.js, Bun and Deno.

function subr(inp,nx,ny,out) {
   for (var iy = 0; iy < ny; iy++) {
      for (var ix = 0; ix < nx; ix++) {
         out[iy * nx + ix] = Math.fround(Math.fround(inp[iy * nx + ix] + Math.fround(ix)) + Math.fround(iy));
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

var inp = new Float32Array(ny * nx);
var out = new Float32Array(ny * nx);
for (var iy = 0; iy < ny; iy++) {
   for (var ix = 0; ix < nx; ix++) {
      inp[iy * nx + ix] = nx - ix + ny - iy;
   }
}

for (var loop = 0; loop < nrpt; loop++) subr(inp,nx,ny,out);

TestLoop:
   for (var iy = 0; iy < ny; iy++) {
      for (var ix = 0; ix < nx; ix++) {
         if (out[iy * nx + ix] != Math.fround(Math.fround(inp[iy * nx + ix] + Math.fround(ix)) + Math.fround(iy))) {
            console.log("Error:",out[iy * nx + ix],iy,ix,inp[iy * nx + ix]);
            break TestLoop;
         }
      }
   }
