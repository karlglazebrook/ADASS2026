# csubpdlpp2.pl -- PDL::PP kernel writing into a preallocated output (2026
# review variant of csubpdlpp.pl).  csubpdlpp.pl calls $In->csub, which
# allocates a fresh nx*ny output ndarray on every repeat; here the output is
# passed in, as every other port does.  GenericTypes limits the generated C
# to float and double, so the same kernel serves the float32 variant
# (csubpdlpp2f.pl: zeroes(float, ...)).
use strict;
use warnings;
use PDL;
BEGIN { mkdir "/tmp/inline_csubpdlpp2" }
use Inline Pdlpp => Config => DIRECTORY => '/tmp/inline_csubpdlpp2';   # own build dir, removed by the cleanup command
use Inline Pdlpp => 'DATA' => BUILD_NOISY => 0 => OPTIMIZE => "-O3";

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

$InArray->csub($OutArray) for 1 .. $nrpt;

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
__DATA__
__Pdlpp__
pp_def('csub',
      Pars => 'i(m,n);[o] o(m,n)',
      GenericTypes => ['F', 'D'],
      Code => '
      loop(n) %{
          loop(m) %{
            $o() = $i() + m + n;
          %}
      %}
      ',
     );
