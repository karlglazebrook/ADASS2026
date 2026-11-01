// csubraw.chpl -- Chapel port (2026).
//
// Chapel, the HPC language from Cray/HPE, has true multidimensional arrays
// over domains. Here a 2D array of real (64-bit) over {0..<ny, 0..<nx},
// indexed A[iy, ix] in a serial nested loop (a `forall` would run it in
// parallel; this stays serial, like every other test). Built with
// `chpl --fast`, which also drops bounds checks; Run.py also has the
// default build, which keeps them.
//
//    chpl --fast csubraw.chpl -o csub_chpl && ./csub_chpl 100 2000 10

proc csub(const ref ina: [] real, nx: int, ny: int, ref outa: [] real) {
  for iy in 0..<ny do
    for ix in 0..<nx do
      outa[iy, ix] = ina[iy, ix] + ix + iy;
}

proc main(args: [] string) {
  var nrpt = 100, nx = 2000, ny = 10;
  if args.size > 1 then nrpt = args[1]: int;
  if args.size > 2 then nx = args[2]: int;
  if args.size > 3 then ny = args[3]: int;
  const D = {0..<ny, 0..<nx};
  var ina, outa: [D] real;
  for (iy, ix) in D do ina[iy, ix] = nx - ix + ny - iy;
  writeln("Arrays ", nx, " by ", ny, " count ", nrpt);
  for 1..nrpt do csub(ina, nx, ny, outa);
  for (iy, ix) in D do
    if outa[iy, ix] != ina[iy, ix] + ix + iy {
      writeln("Error: ", ix, " ", iy);
      break;
    }
}
