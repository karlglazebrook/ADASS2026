# csubpdlary2_f32.pl -- float32 PDL whole-array variant without temporaries (2026 review
# variant of csubpdlary.pl).  The 2019 form  $Out .= $In + seq(nx) + seq(ny)->dummy(0,1)
# builds two nx*ny temporaries and then copies.  Here the explicit-output
# form of PDL::Ops::plus writes straight into $Output, then the row index is
# added in place: two passes, no full-size temporaries.
use strict;
use warnings;
use PDL;

sub csub {
   my ($Input, $Nx, $Ny, $Output) = @_;
   $Input->plus(sequence(float, $Nx), $Output, 0);               # out = in + ix
   $Output->inplace->plus(sequence(float, $Ny)->dummy(0, 1), 0);  # out += iy
}

my ($nrpt, $nx, $ny) = (10000, 2000, 10);
$nrpt = $ARGV[0] if @ARGV > 0;
$nx   = $ARGV[1] if @ARGV > 1;
$ny   = $ARGV[2] if @ARGV > 2;
print "Arrays $nx columns by $ny rows, repeats = $nrpt\n";

my $InArray  = zeroes(float, $nx, $ny);
my $OutArray = zeroes(float, $nx, $ny);
foreach my $iy (0 .. $ny - 1) {
   foreach my $ix (0 .. $nx - 1) {
      $InArray->set($ix, $iy, $nx - $ix + $ny - $iy);
   }
}

csub($InArray, $nx, $ny, $OutArray) for 1 .. $nrpt;

my $err = 0;
for (my $iy = 0; $iy < $ny && !$err; $iy++) {
   for (my $ix = 0; $ix < $nx && !$err; $ix++) {
      my $got  = $OutArray->at($ix, $iy);
      my $want = $InArray->at($ix, $iy) + $ix + $iy;
      if ($got != $want) {
         print "Error: got=$got want=$want at ix=$ix iy=$iy\n";
         $err = 1;
      }
   }
}
