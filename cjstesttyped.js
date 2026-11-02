//  cjstesttyped.js -- JavaScript, Array of Float64Array rows (2026).
//  Nested layout like Keith's cjstest.js, but each row is a typed Float64Array
//  (unboxed doubles), the JS counterpart of C#'s double[][] and Kotlin's
//  Array<DoubleArray>. Rows are hoisted. Runs in Node.js, Bun and Deno.
function subr(inp,nx,ny,out) {
   for (var iy = 0; iy < ny; iy++) {
      var rin = inp[iy], rout = out[iy];
      for (var ix = 0; ix < nx; ix++) {
         rout[ix] = rin[ix] + ix + iy;
      }
   }
}
var nargs = process.argv.length;
var ny = 10, nx = 2000, nrpt = 1000;
if (nargs > 2) nrpt = parseInt(process.argv[2]);
if (nargs > 3) nx = parseInt(process.argv[3]);
if (nargs > 4) ny = parseInt(process.argv[4]);
console.log ("Arrays,",ny,"rows of",nx,"columns, repeat = ",nrpt);
var inp = new Array(ny), out = new Array(ny);
for (var iy = 0; iy < ny; iy++) {
   inp[iy] = new Float64Array(nx); out[iy] = new Float64Array(nx);
   for (var ix = 0; ix < nx; ix++) inp[iy][ix] = nx - ix + ny - iy;
}
for (var loop = 0; loop < nrpt; loop++) subr(inp,nx,ny,out);
TestLoop:
   for (var iy = 0; iy < ny; iy++)
      for (var ix = 0; ix < nx; ix++)
         if (out[iy][ix] != (inp[iy][ix] + ix + iy)) {
            console.log("Error:",out[iy][ix],iy,ix,inp[iy][ix]); break TestLoop;
         }
