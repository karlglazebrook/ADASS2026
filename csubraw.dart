// csubraw.dart -- Dart port (2026).
//
// Rows are Float64List (dart:typed_data, unboxed doubles) in a List, indexed
// element by element. Dart's own toolchain runs the same file two ways:
// `dart run` uses the Dart VM's JIT; `dart compile exe` compiles it ahead of
// time to a native executable. Run.py has both.
//
//    dart run csubraw.dart 100 2000 10
//    dart compile exe csubraw.dart -o csub_dart && ./csub_dart 100 2000 10

import 'dart:typed_data';

void csub(List<Float64List> ina, int nx, int ny, List<Float64List> out) {
  for (var iy = 0; iy < ny; iy++) {
    final inrow = ina[iy];
    final outrow = out[iy];
    for (var ix = 0; ix < nx; ix++) {
      outrow[ix] = inrow[ix] + ix + iy;
    }
  }
}

void main(List<String> args) {
  final nrpt = args.isNotEmpty ? int.parse(args[0]) : 100;
  final nx = args.length > 1 ? int.parse(args[1]) : 2000;
  final ny = args.length > 2 ? int.parse(args[2]) : 10;
  final ina = List.generate(ny, (iy) => Float64List.fromList(
      List.generate(nx, (ix) => (nx - ix + ny - iy).toDouble())));
  final out = List.generate(ny, (_) => Float64List(nx));
  print('Arrays $nx by $ny count $nrpt');
  for (var r = 0; r < nrpt; r++) {
    csub(ina, nx, ny, out);
  }
  for (var iy = 0; iy < ny; iy++) {
    for (var ix = 0; ix < nx; ix++) {
      if (out[iy][ix] != ina[iy][ix] + ix + iy) {
        print('Error: ${out[iy][ix]} $ix $iy ${ina[iy][ix]}');
        return;
      }
    }
  }
}
