# csubrows.raku -- Raku "raw" with the row arrays hoisted (2026 review variant
# of csubraw.raku).  Same boxed Arrays of Arrays; the two row lookups move
# out of the inner loop by binding the rows once per iy.
sub csub(@in, $nx, $ny, @out) {
    for ^$ny -> $iy {
        my @i := @in[$iy];
        my @o := @out[$iy];
        for ^$nx -> $ix {
            @o[$ix] = @i[$ix] + $ix + $iy;
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
