# csubraw.raku -- Raku port, "raw" (2026).
#
# Keith's csubraw.py/csubraw.pl in Raku: Arrays of Arrays of ordinary
# (boxed) values, indexed element by element with range loops. Rakudo runs
# on MoarVM, whose runtime specialiser ("spesh") and JIT optimise hot code
# as it runs; MVM_SPESH_DISABLE=1 turns both off (Run.py has that variant).
#
#    raku csubraw.raku 100 2000 10

sub csub(@in, $nx, $ny, @out) {
    for ^$ny -> $iy {
        for ^$nx -> $ix {
            @out[$iy][$ix] = @in[$iy][$ix] + $ix + $iy;
        }
    }
}

my $nrpt = (@*ARGS[0] // 3).Int;
my $nx = (@*ARGS[1] // 2000).Int;
my $ny = (@*ARGS[2] // 10).Int;
say "Arrays $nx columns by $ny rows, repeats = $nrpt";

my @in = (^$ny).map(-> $iy { [ (^$nx).map(-> $ix { ($nx - $ix + $ny - $iy).Num }) ] });
my @out = (^$ny).map({ [ 0e0 xx $nx ] });

csub(@in, $nx, $ny, @out) for ^$nrpt;

CHECK: for ^$ny -> $iy {
    for ^$nx -> $ix {
        if @out[$iy][$ix] != @in[$iy][$ix] + $ix + $iy {
            say "Error $ix $iy @in[$iy][$ix] @out[$iy][$ix]";
            last CHECK;
        }
    }
}
