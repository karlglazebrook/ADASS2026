//  cjstestrows.js -- Keith's cjstest.js with the row arrays hoisted (2026).
//  Same Array-of-Arrays storage; the only change is that inp[iy] and out[iy]
//  are loaded once per row instead of once per element.
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
   inp[iy] = new Array(nx); out[iy] = new Array(nx);
   for (var ix = 0; ix < nx; ix++) { inp[iy][ix] = nx - ix + ny - iy; out[iy][ix] = 0.0; }
}
for (var loop = 0; loop < nrpt; loop++) subr(inp,nx,ny,out);
TestLoop:
   for (var iy = 0; iy < ny; iy++)
      for (var ix = 0; ix < nx; ix++)
         if (out[iy][ix] != (inp[iy][ix] + ix + iy)) {
            console.log("Error:",out[iy][ix],iy,ix,inp[iy][ix]); break TestLoop;
         }
