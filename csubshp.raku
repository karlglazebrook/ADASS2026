# csubshp.raku -- Raku port with a shaped native 2D array (2026).
#
# Raku's own multidimensional arrays: `my num @a[$ny;$nx]` is one shaped
# array of native doubles, indexed as @a[$iy;$ix]. This is the closest Raku
# has to a Fortran or numpy 2D array, with native int loop counters.
#
#    raku csubshp.raku 100 2000 10

sub csub(@in, int $nx, int $ny, @out) {
    loop (my int $iy = 0; $iy < $ny; $iy++) {
        loop (my int $ix = 0; $ix < $nx; $ix++) {
            @out[$iy;$ix] = @in[$iy;$ix] + $ix + $iy;
        }
    }
}

my $nrpt = (@*ARGS[0] // 3).Int;
my $nx = (@*ARGS[1] // 2000).Int;
my $ny = (@*ARGS[2] // 10).Int;
say "Arrays $nx columns by $ny rows, repeats = $nrpt";

my num @in[$ny;$nx];
my num @out[$ny;$nx];
for ^$ny -> $iy {
    for ^$nx -> $ix {
        @in[$iy;$ix] = ($nx - $ix + $ny - $iy).Num;
    }
}

csub(@in, $nx, $ny, @out) for ^$nrpt;

CHECK: for ^$ny -> $iy {
    for ^$nx -> $ix {
        if @out[$iy;$ix] != @in[$iy;$ix] + $ix + $iy {
            say "Error $ix $iy @in[$iy;$ix] @out[$iy;$ix]";
            last CHECK;
        }
    }
}
