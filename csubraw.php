<?php
// csubraw.php -- PHP port (2026).
//
// Keith's list version in PHP: arrays of row arrays of floats, indexed
// element by element. PHP arrays are ordered hash maps, stored as packed
// vectors when the keys are 0..n-1, as here. PHP 8 has a JIT inside its
// opcache, off by default on the command line; Run.py runs this file with
// and without it:
//    php csubraw.php 100 2000 10
//    php -d opcache.enable_cli=1 -d opcache.jit=tracing \
//        -d opcache.jit_buffer_size=64M csubraw.php 100 2000 10

function csub(array $in, int $nx, int $ny, array &$out): void {
    for ($iy = 0; $iy < $ny; $iy++) {
        for ($ix = 0; $ix < $nx; $ix++) {
            $out[$iy][$ix] = $in[$iy][$ix] + $ix + $iy;
        }
    }
}

$nrpt = (int)($argv[1] ?? 100);
$nx = (int)($argv[2] ?? 2000);
$ny = (int)($argv[3] ?? 10);
$in = [];
$out = [];
for ($iy = 0; $iy < $ny; $iy++) {
    for ($ix = 0; $ix < $nx; $ix++) {
        $in[$iy][$ix] = (float)($nx - $ix + $ny - $iy);
        $out[$iy][$ix] = 0.0;
    }
}
echo "Arrays $nx by $ny count $nrpt\n";
for ($r = 0; $r < $nrpt; $r++) {
    csub($in, $nx, $ny, $out);
}
for ($iy = 0; $iy < $ny; $iy++) {
    for ($ix = 0; $ix < $nx; $ix++) {
        if ($out[$iy][$ix] != $in[$iy][$ix] + $ix + $iy) {
            echo "Error: {$out[$iy][$ix]} $ix $iy {$in[$iy][$ix]}\n";
            break 2;
        }
    }
}
