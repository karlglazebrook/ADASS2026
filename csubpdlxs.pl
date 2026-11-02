# csubpdlxs.pl -- PDL element loop calling the XS primitives directly (2026
# review variant of csubpdl.pl).  PDL::at and PDL::set are thin Perl wrappers
# around PDL::Core::at_bad_c / set_c that shift/pop @_ and rebuild an index
# list; calling the XS functions directly removes one Perl sub call and a
# method dispatch per element.  Still ->at/->set semantics, never ->slice.
use strict;
use warnings;
use PDL;

sub csub {
   my ($Input, $Nx, $Ny, $Output) = @_;
   foreach my $iy (0 .. $Ny - 1) {
      foreach my $ix (0 .. $Nx - 1) {
         PDL::Core::set_c($Output, [$ix, $iy],
                          PDL::Core::at_bad_c($Input, [$ix, $iy]) + $ix + $iy);
      }
   }
}

my ($nrpt, $nx, $ny) = (3, 2000, 10);
$nrpt = $ARGV[0] if @ARGV > 0;
$nx   = $ARGV[1] if @ARGV > 1;
$ny   = $ARGV[2] if @ARGV > 2;
print "Arrays $nx columns by $ny rows, repeats = $nrpt\n";

my $InArray  = zeroes($nx, $ny);
my $OutArray = zeroes($nx, $ny);
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
