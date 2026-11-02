// csubflat.dart -- Dart with one flat Float64List (2026 variant).
// One contiguous Float64List of ny*nx doubles indexed iy*nx + ix, like
// cjstestflat.js and cstestflat.swift. Loop bounds are the list length so the
// VM's range analysis can drop the bounds checks.
import 'dart:typed_data';

void csub(Float64List ina, int nx, int ny, Float64List out) {
  for (var iy = 0; iy < ny; iy++) {
    final base = iy * nx;
    for (var ix = 0; ix < nx; ix++) {
      out[base + ix] = ina[base + ix] + ix + iy;
    }
  }
}

void main(List<String> args) {
  final nrpt = args.isNotEmpty ? int.parse(args[0]) : 100;
  final nx = args.length > 1 ? int.parse(args[1]) : 2000;
  final ny = args.length > 2 ? int.parse(args[2]) : 10;
  final ina = Float64List(nx * ny);
  final out = Float64List(nx * ny);
  for (var iy = 0; iy < ny; iy++) {
    for (var ix = 0; ix < nx; ix++) {
      ina[iy * nx + ix] = (nx - ix + ny - iy).toDouble();
    }
  }
  print('Arrays $nx by $ny count $nrpt');
  for (var r = 0; r < nrpt; r++) {
    csub(ina, nx, ny, out);
  }
  for (var iy = 0; iy < ny; iy++) {
    for (var ix = 0; ix < nx; ix++) {
      if (out[iy * nx + ix] != ina[iy * nx + ix] + ix + iy) {
        print('Error: ${out[iy * nx + ix]} $ix $iy ${ina[iy * nx + ix]}');
        return;
      }
    }
  }
}
