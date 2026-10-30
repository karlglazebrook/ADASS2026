#  csubpdl.pl -- PDL "raw" per-element access test.
#
#  History note: the 2019 study by Shortridge implemented this test
#  using ->slice($ix,$iy) for both reads and writes.  That choice
#  was a mistake -- ->slice constructs a 1-element slice piddle on
#  every access, which makes the per-element overhead pathologically
#  bad (~10^5x relative time).  The 2026 reprise replaces it with
#  ->at($ix,$iy) for reads and ->set($ix,$iy,$v) for writes, the
#  per-element primitives PDL was actually designed to expose.
#  This is the *correct* PDL analogue of csubnp.py (numpy raw).
#  It is still slow -- you are looping in Perl, calling into C on
#  every element -- but in the same broad ballpark as numpy raw,
#  not an order of magnitude worse.

use PDL;

sub csub {
   my ($Input,$Nx,$Ny,$Output) = @_;
   for (my $iy=0; $iy < $Ny; $iy++) {
      for (my $ix=0; $ix < $Nx; $ix++) {
         $Output->set($ix, $iy, $Input->at($ix, $iy) + $ix + $iy);
      }
   }
}

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

$InArray  = zeroes($nx,$ny);
$OutArray = zeroes($nx,$ny);
for (my $iy=0; $iy < $ny; $iy++) {
   for (my $ix=0; $ix < $nx; $ix++) {
      $InArray->set($ix, $iy, $nx - $ix + $ny - $iy);
   }
}

for (my $irpt = 0; $irpt < $nrpt; $irpt++) {
   csub($InArray, $nx, $ny, $OutArray);
}

# check
my $err = 0;
for (my $iy=0; $iy < $ny && !$err; $iy++) {
   for (my $ix=0; $ix < $nx && !$err; $ix++) {
      my $got  = $OutArray->at($ix, $iy);
      my $want = $InArray->at($ix, $iy) + $ix + $iy;
      if ($got != $want) {
         print "Error: got=$got want=$want at ix=$ix iy=$iy\n";
         $err = 1;
      }
   }
}
