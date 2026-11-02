# csubinlav2.pl -- Inline::C over Perl arrays of arrays, direct AvARRAY access
# (2026 review variant of csubinlav.pl).  av_fetch() is replaced by indexing
# the AV's SV* vector directly, the usual XS idiom when the array is known
# to be dense; the value store uses sv_setnv as before.
use strict;
use warnings;
BEGIN { mkdir "/tmp/inline_csubinlav2" }
use Inline C => Config => DIRECTORY => '/tmp/inline_csubinlav2';   # own build dir, removed by the cleanup command
use Inline C => 'DATA', OPTIMIZE => '-O3';

my ($nrpt, $nx, $ny) = (3, 2000, 10);
$nrpt = $ARGV[0] if @ARGV > 0;
$nx   = $ARGV[1] if @ARGV > 1;
$ny   = $ARGV[2] if @ARGV > 2;
print "Arrays $nx columns by $ny rows, repeats = $nrpt\n";

my @InArray  = map { my $iy = $_; [ map { $nx - $iy + $ny - $_ } 0 .. $nx - 1 ] } 0 .. $ny - 1;
my @OutArray = map { [ (0.0) x $nx ] } 0 .. $ny - 1;

csub(\@InArray, $nx, $ny, \@OutArray) for 1 .. $nrpt;

CHECK: foreach my $iy (0 .. $ny - 1) {
   foreach my $ix (0 .. $nx - 1) {
      if ($OutArray[$iy][$ix] != $InArray[$iy][$ix] + $ix + $iy) {
         print "Error $ix $iy $InArray[$iy][$ix] $OutArray[$iy][$ix]\n";
         last CHECK;
      }
   }
}
__DATA__
__C__
void csub(SV* inref, int nx, int ny, SV* outref) {
   AV* in  = (AV*) SvRV(inref);
   AV* out = (AV*) SvRV(outref);
   int ix, iy;
   for (iy = 0; iy < ny; iy++) {
      SV** inrow  = AvARRAY((AV*) SvRV(AvARRAY(in)[iy]));
      SV** outrow = AvARRAY((AV*) SvRV(AvARRAY(out)[iy]));
      for (ix = 0; ix < nx; ix++) {
         sv_setnv(outrow[ix], SvNV(inrow[ix]) + ix + iy);
      }
   }
}
