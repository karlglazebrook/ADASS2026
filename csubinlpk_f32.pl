# csubinlpk_f32.pl -- Inline::C over packed float32 strings (2026 review variant
# of csubinlpk.pl): pack("f*") instead of pack("d*"), kernel in float.
use strict;
use warnings;
BEGIN { mkdir "/tmp/inline_csubinlpk_f32" }
use Inline C => Config => DIRECTORY => '/tmp/inline_csubinlpk_f32';   # own build dir, removed by the cleanup command
use Inline C => 'DATA', OPTIMIZE => '-O3';

my ($nrpt, $nx, $ny) = (3, 2000, 10);
$nrpt = $ARGV[0] if @ARGV > 0;
$nx   = $ARGV[1] if @ARGV > 1;
$ny   = $ARGV[2] if @ARGV > 2;
print "Arrays $nx columns by $ny rows, repeats = $nrpt\n";

my @in;
foreach my $iy (0 .. $ny - 1) {
   push @in, $nx - $iy + $ny - $_ for 0 .. $nx - 1;
}
my $InArray  = pack("f*", @in);
my $OutArray = pack("f*", (0.0) x ($nx * $ny));

csub($InArray, $nx, $ny, $OutArray) for 1 .. $nrpt;

my @out = unpack("f*", $OutArray);
CHECK: foreach my $iy (0 .. $ny - 1) {
   foreach my $ix (0 .. $nx - 1) {
      my $k = $iy * $nx + $ix;
      if ($out[$k] != $in[$k] + $ix + $iy) {
         print "Error $ix $iy $in[$k] $out[$k]\n";
         last CHECK;
      }
   }
}
__DATA__
__C__
void csub(SV* insv, int nx, int ny, SV* outsv) {
   const float* in = (const float*) SvPVX(insv);
   float* out = (float*) SvPVX(outsv);
   int ix, iy;
   for (iy = 0; iy < ny; iy++) {
      for (ix = 0; ix < nx; ix++) {
         out[iy * nx + ix] = in[iy * nx + ix] + ix + iy;
      }
   }
}
