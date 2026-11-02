// csubf32.dart -- Dart float32 variant of csubraw.dart (2026).
// Rows are Float32List; Dart arithmetic is always double, so each element is
// widened on read and narrowed on write, but memory traffic is halved.
import 'dart:typed_data';

void csub(List<Float32List> ina, int nx, int ny, List<Float32List> out) {
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
  final ina = List<Float32List>.generate(ny, (iy) => Float32List.fromList(
      List.generate(nx, (ix) => (nx - ix + ny - iy).toDouble())), growable: false);
  final out = List<Float32List>.generate(ny, (_) => Float32List(nx), growable: false);
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
