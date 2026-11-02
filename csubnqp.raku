# csubnqp.raku -- Raku native rows through nqp:: ops (2026 review variant of
# csubnat.raku).  `use nqp` exposes the MoarVM-level array ops the Rakudo
# core itself uses for hot loops; nqp::atpos_n / nqp::bindpos_n read and
# write a native num array without going through AT-POS/ASSIGN-POS method
# dispatch.  Not portable Raku: it is Rakudo-specific, and labelled so.
use nqp;

sub csub(@in, int $nx, int $ny, @out) {
    loop (my int $iy = 0; $iy < $ny; $iy++) {
        my num @i := @in[$iy];
        my num @o := @out[$iy];
        loop (my int $ix = 0; $ix < $nx; $ix++) {
            nqp::bindpos_n(@o, $ix, nqp::add_n(nqp::atpos_n(@i, $ix), nqp::coerce_in($ix + $iy)));
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
