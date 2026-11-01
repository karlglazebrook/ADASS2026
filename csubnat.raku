# csubnat.raku -- Raku port with native types (2026).
#
# The csubraw.raku loop, but each row is a native num array (unboxed
# doubles, like a C array) and the loop counters are native ints, in
# C-style loops: the "give the compiler the types" form. Range loops with
# `-> int $ix` were tried and are no faster. MVM_SPESH_DISABLE=1 turns off
# MoarVM's runtime specialiser and JIT (Run.py has that variant).
#
#    raku csubnat.raku 100 2000 10

sub csub(@in, int $nx, int $ny, @out) {
    loop (my int $iy = 0; $iy < $ny; $iy++) {
        my num @i := @in[$iy];
        my num @o := @out[$iy];
        loop (my int $ix = 0; $ix < $nx; $ix++) {
            @o[$ix] = @i[$ix] + $ix + $iy;
        }
    }
}

my $nrpt = (@*ARGS[0] // 3).Int;
my $nx = (@*ARGS[1] // 2000).Int;
my $ny = (@*ARGS[2] // 10).Int;
say "Arrays $nx columns by $ny rows, repeats = $nrpt";

my @in = (^$ny).map(-> $iy { my num @r = (^$nx).map(-> $ix { ($nx - $ix + $ny - $iy).Num }); @r });
my @out = (^$ny).map({ my num @r = 0e0 xx $nx; @r });

csub(@in, $nx, $ny, @out) for ^$nrpt;

CHECK: for ^$ny -> $iy {
    for ^$nx -> $ix {
        if @out[$iy][$ix] != @in[$iy][$ix] + $ix + $iy {
            say "Error $ix $iy @in[$iy][$ix] @out[$iy][$ix]";
            last CHECK;
        }
    }
}
