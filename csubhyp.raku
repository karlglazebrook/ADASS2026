# csubhyp.raku -- Raku port, whole-row hyperoperators (2026).
#
# The vectorised idiom, like numpy "vectors": each output row is the input
# row plus the index row in one hyperoperator expression, »+«, instead of an
# element loop. ($iy ..^ $iy + $nx) is the row of ix + iy values.
#
#    raku csubhyp.raku 100 2000 10

sub csub(@in, $nx, $ny, @out) {
    for ^$ny -> $iy {
        @out[$iy] = [ @in[$iy].list »+« ($iy ..^ $iy + $nx) ];
    }
}

my $nrpt = (@*ARGS[0] // 3).Int;
my $nx = (@*ARGS[1] // 2000).Int;
my $ny = (@*ARGS[2] // 10).Int;
say "Arrays $nx columns by $ny rows, repeats = $nrpt";

my @in = (^$ny).map(-> $iy { [ (^$nx).map(-> $ix { ($nx - $ix + $ny - $iy).Num }) ] });
my @out;

csub(@in, $nx, $ny, @out) for ^$nrpt;

CHECK: for ^$ny -> $iy {
    for ^$nx -> $ix {
        if @out[$iy][$ix] != @in[$iy][$ix] + $ix + $iy {
            say "Error $ix $iy @in[$iy][$ix] @out[$iy][$ix]";
            last CHECK;
        }
    }
}
