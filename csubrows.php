<?php
// csubrows.php -- csubraw.php with the row arrays hoisted (2026 review variant).
// The input row is read once per iy and the output row is taken by reference,
// so the inner loop does one packed-array read and one write per element
// instead of two nested dimension fetches each.
function csub(array $in, int $nx, int $ny, array &$out): void {
    for ($iy = 0; $iy < $ny; $iy++) {
        $rin = $in[$iy];
        $rout = &$out[$iy];
        for ($ix = 0; $ix < $nx; $ix++) {
            $rout[$ix] = $rin[$ix] + $ix + $iy;
        }
        unset($rout);
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
