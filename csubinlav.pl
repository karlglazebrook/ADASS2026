#!/usr/bin/env perl
#                       c s u b i n l a v . p l
#
#  Inline::C on Perl's own arrays (2026). The data are exactly as in
#  csubraw.pl, an array of references to row arrays of Perl scalars, but
#  csub() is written in C (compiled and cached by Inline::C on first run,
#  hence the warm-up build step in Run.py). The C still has to fetch each
#  row and each element through the Perl API (av_fetch, SvNV, sv_setnv), so
#  this measures Perl's boxed data with the interpreter loop taken away.
#  Compare csubinlpk.pl, the same C on packed doubles, and csubpdlpp.pl.

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

my @InArray;
my @OutArray;
for (my $iy=0; $iy < $ny; $iy++) {
   for (my $ix=0; $ix < $nx; $ix++) {
      $InArray[$iy][$ix] = $nx - $iy + $ny - $ix;
      $OutArray[$iy][$ix] = 0.0;
   }
}

for (my $irpt = 0; $irpt < $nrpt; $irpt++) {
   csub (\@InArray,$nx,$ny,\@OutArray);
}

Loop: {
   for (my $iy=0; $iy < $ny; $iy++) {
      for (my $ix=0; $ix < $nx; $ix++) {
         if ($OutArray[$iy][$ix] != $InArray[$iy][$ix] + $ix + $iy) {
            print "Error ",$ix," ",$iy," ",
                        $InArray[$iy][$ix]," ",$OutArray[$iy][$ix],"\n";
            last Loop;
         }
      }
   }
}

__DATA__
__C__

void csub(SV* inref, int nx, int ny, SV* outref) {
   AV* in = (AV*) SvRV(inref);
   AV* out = (AV*) SvRV(outref);
   int ix, iy;
   for (iy = 0; iy < ny; iy++) {
      AV* inrow = (AV*) SvRV(*av_fetch(in, iy, 0));
      AV* outrow = (AV*) SvRV(*av_fetch(out, iy, 0));
      for (ix = 0; ix < nx; ix++) {
         sv_setnv(*av_fetch(outrow, ix, 0), SvNV(*av_fetch(inrow, ix, 0)) + ix + iy);
      }
   }
}
