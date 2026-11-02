// csubraw32.chpl -- Chapel port, real(32) (2026 review variant).
//
// csubraw.chpl with 32-bit reals, the precision of Keith's C, Fortran and
// Julia kernels. Everything else is unchanged: a 2D array over the domain
// {0..<ny, 0..<nx}, indexed A[iy, ix] in a serial nested loop.
//
//    chpl --fast csubraw32.chpl -o csub_chpl32 && ./csub_chpl32 100 2000 10

proc csub(const ref ina: [] real(32), nx: int, ny: int, ref outa: [] real(32)) {
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
  var ina, outa: [D] real(32);
  for (iy, ix) in D do ina[iy, ix] = nx - ix + ny - iy;
  writeln("Arrays ", nx, " by ", ny, " count ", nrpt);
  for 1..nrpt do csub(ina, nx, ny, outa);
  for (iy, ix) in D do
    if outa[iy, ix] != ina[iy, ix] + ix + iy {
      writeln("Error: ", ix, " ", iy);
      break;
    }
}
