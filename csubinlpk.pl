#!/usr/bin/env perl
#                       c s u b i n l p k . p l
#
#  Inline::C on packed doubles (2026). Each array is one Perl string holding
#  ny*nx native doubles (pack "d*"), row by row, so csub() is plain C on a
#  double* with no Perl API in the loop: the same trick as PDL::PP, without
#  PDL. Compiled and cached by Inline::C on first run, hence the warm-up
#  build step in Run.py. Compare csubinlav.pl and csubpdlpp.pl.

use Inline C => 'DATA', OPTIMIZE => '-O3';

$nx = 2000;
$ny = 10;
$nrpt = 3;
if ($#ARGV >= 0) {
   $nrpt = $ARGV[0];
   if ($#ARGV >= 1) {
      $nx = $ARGV[1];
      if ($#ARGV >= 2) {
         $ny = $ARGV[2];
      }
   }
}
print ("Arrays ",$nx," columns by ",$ny," rows, repeats = ",$nrpt,"\n");

my @in;
for (my $iy=0; $iy < $ny; $iy++) {
   for (my $ix=0; $ix < $nx; $ix++) {
      push @in, $nx - $iy + $ny - $ix;
   }
}
my $InArray = pack("d*", @in);
my $OutArray = pack("d*", (0.0) x ($nx * $ny));

for (my $irpt = 0; $irpt < $nrpt; $irpt++) {
   csub ($InArray,$nx,$ny,$OutArray);
}

my @out = unpack("d*", $OutArray);
Loop: {
   for (my $iy=0; $iy < $ny; $iy++) {
      for (my $ix=0; $ix < $nx; $ix++) {
         my $k = $iy * $nx + $ix;
         if ($out[$k] != $in[$k] + $ix + $iy) {
            print "Error ",$ix," ",$iy," ",$in[$k]," ",$out[$k],"\n";
            last Loop;
         }
      }
   }
}

__DATA__
__C__

void csub(SV* insv, int nx, int ny, SV* outsv) {
   const double* in = (const double*) SvPVX(insv);
   double* out = (double*) SvPVX(outsv);
   int ix, iy;
   for (iy = 0; iy < ny; iy++) {
      for (ix = 0; ix < nx; ix++) {
         out[iy * nx + ix] = in[iy * nx + ix] + ix + iy;
      }
   }
}
