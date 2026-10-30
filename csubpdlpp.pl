#
#                          c s u b p d l p p . p l
#
#  Summary:
#     2D array access test in Perl, using Inline::Pdlpp.
#
#  Introduction:
#     This is a test program written as part of a study into how well different
#     languages handle accessing elements of 2D rectangular arrays - the sort of
#     thing that are common in astronomy and similar scientific disciplines.
#     This can also be used to see how efficient different ways of coding the
#     same problem can be in the different languages, and to see what effect
#     such things as compilation options - particularly optimisation options -
#     have.
#
#     The problem chosen is a trivial one: given an 2D array, add to each
#     element the sum of its two indices and return the result in a second,
#     similarly-sized array. This is harder to optimise away than, for example,
#     simply doing an element by element copy of the array, but is generally
#     easy to code. It isn't a perfect test (something brought out by the
#     study), but it does produce some interesting results.
#
#  This version:
#     This version is for Perl, and uses the PDL (Perl Data Language)
#     sub-system to work with multi-dimensional arrays. PDL is akin to numpy
#     for Python, in that it is designed to provide relatively fast operations
#     on arrays, and it has a very flexible syntax for slicing arrays. This
#     version uses Inline::Pdlpp to allow compiled PDL code to be called
#     directly from Perl.
#
#  Structure:
#     Most test programs in this study code the basic array manipulation in a
#     single subroutine, then create the original input array, and pass that,
#     together with the dimensions of the array, to that subroutine, repeating
#     that call a large number of times in oder to be able to get a reasonable
#     estimate of the time taken. Then the final result is checked against the
#     expected result.
#
#     This code follows that structure, with both the main routine and the
#     called subroutine in the same piece of code, as Perl/PDL doesn't optimise
#     out the call in that case.
#
#  Invocation:
#     perl csubpdl.pl irpt nx ny
#
#     where
#        irpt  is the number of times the subroutine is called - default 3.
#        nx    is the number of columns in the array tested - default 2000.
#        ny    is the number of rows in the array tested - default 10.
#
#     This assumes that the Perl installation supports PDL.
#
#     Note that Perl/PDL uses column-major order; arrays are stored in memory so
#     that the first index varies fastest.
#
#  Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
#
#  History:
#      4th Dec 2023. Based on csubraw.pl, but using Inline::Pdlpp as suggested
#                    by Karl Glazebrook - thanks, Karl. KS.
#      8th Jan 2024. Modified the 'use inline' setings as suggested by Karl, and
#                    added some explanatory comments. KS.
#
#  Copyright (c) 2023 Knave and Varlet
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#  SOFTWARE.

use PDL;

#  This line controls the building of the inline code. The BUILD_NOISY value can
#  be set to 1 to generate quite a lot of diagnostics from the build phase. The
#  OPTIMIZE value controls the optimisation. -O0 turns off optimisation, leaving
#  the OPTIMIZE specification out will use the optimisation settings used when
#  perl was built.

use Inline Pdlpp => 'DATA' => BUILD_NOISY =>  0 =>  OPTIMIZE =>  "-O3";

#  -----------------------------------------------------------------------------

#  The main routine.

#  Get the command line arguments, and determine the array size and the number
#  of times to repeat the subroutine call.

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

#  Create the input array and output arrays. We set the elements of the input
#  array to some set of values - it doesn't matter what, just some values we
#  can use to check the array manipulation on. This uses the sum of the row and
#  column indices in descending order. The values in the output array don't
#  matter, so we fill it with zeros.

$InArray = zeroes($nx,$ny);
$OutArray = zeroes($nx,$ny);
for (my $iy=0; $iy < $ny; $iy++) {
   for (my $ix=0; $ix < $nx; $ix++) {
      $InArray->slice($ix,$iy) .= $nx - $ix + $ny - $iy;
   }
}

#  Call the subroutine the specified number of times.

for (my $irpt = 0; $irpt < $nrpt; $irpt++) {
   $OutArray = $InArray->csub;
}

#  Check the results.

Loop: {
   for (my $iy=0; $iy < $ny; $iy++) {
      for (my $ix=0; $ix < $nx; $ix++) {
         if ($OutArray->slice($ix,$iy)
                            != $InArray->slice($ix,$iy) + $ix + $iy) {
            print "Error ",$ix," ",$iy," ",$InArray->slice($ix,$iy)," ",
                                          $OutArray->slice($ix,$iy),"\n";
            last Loop;
         }
      }
   }
}

#  --------------------------------------------------------------------------------
#
#  The csub() subroutine.
#
#  csub is a subroutine that is passed a two-dimensional floating point array
#  Input, with dimensions Nx by Ny, and returns a second, array, Output,
#  of the same dimensions. It returns with each element of Output set to the
#  contents of the corresponding element of Input plus the sum of its two
#  indices. It is defined in this __DATA__ section and should be compiled
#  directly into callable code.

__DATA__

__Pdlpp__

pp_def('csub',
      Pars => 'i(m,n);[o] o(m,n)',
      Code => '
      
      loop(n) %{
          loop(m) %{
            $o() = $i() + m+n;
          %}
      %}
      ',
     );

#  --------------------------------------------------------------------------------

#                       P r o g r a m m i n g  N o t e s
#
#  o The loops that set up the input array, and test the output array after the
#    opearation has been performed as many times as requested, use the very
#    slow PDL single element access method. For small repeat counts, these
#    could well have a significant overhead, and this needs to be allowed for
#    in the timeing - probably by measuring the time for a run with nrpt set
#    to one, repeating for the full repeat count and adjusting the time taken.
#
#  o The first time this is run, there will be a significant overhead as the
#    code for csub() is compiled. But this is cached, and subsequent runs should
#    avoid this overhead.
#
#  o At the moment, this is very experiental, and I'm not sure the -O3 optimise
#    flag is being honoured.

