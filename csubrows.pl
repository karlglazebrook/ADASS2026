# csubrows.pl -- Perl element loop, idiomatic modern form (2026 review variant).
# Same work as csubraw.pl: foreach over ranges (Perl optimises a foreach over
# a literal range into a counting loop, no list is built), row references
# hoisted out of the inner loop, strict/warnings on.
use strict;
use warnings;

sub csub {
   my ($Input, $Nx, $Ny, $Output) = @_;
   foreach my $iy (0 .. $Ny - 1) {
      my $in  = $Input->[$iy];
      my $out = $Output->[$iy];
      foreach my $ix (0 .. $Nx - 1) {
         $out->[$ix] = $in->[$ix] + $ix + $iy;
      }
   }
}

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
