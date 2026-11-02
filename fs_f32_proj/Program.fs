// fs_f32_proj/Program.fs -- F# float32 variant of fs_proj (2026).
//
// Identical to fs_proj/Program.fs with float32 (single) arrays and
// conversions, keeping the `for .. in` range loops of the original.

module CsubRaw

let subr (inp: float32[][]) (nx: int) (ny: int) (out: float32[][]) : unit =
    for iy in 0 .. ny - 1 do
        let rowIn  = inp.[iy]
        let rowOut = out.[iy]
        let fiy    = float32 iy
        for ix in 0 .. nx - 1 do
            rowOut.[ix] <- rowIn.[ix] + float32 ix + fiy

[<EntryPoint>]
let main args =
    let nrpt = if args.Length > 0 then int args.[0] else 1000
    let nx   = if args.Length > 1 then int args.[1] else 2000
    let ny   = if args.Length > 2 then int args.[2] else 10

    let inp  = Array.init ny (fun _ -> Array.zeroCreate<float32> nx)
    let out  = Array.init ny (fun _ -> Array.zeroCreate<float32> nx)
    for iy in 0 .. ny - 1 do
        for ix in 0 .. nx - 1 do
            inp.[iy].[ix] <- float32 (nx - ix + ny - iy)

    printfn "Arrays %d by %d count %d" nx ny nrpt

    for _ in 1 .. nrpt do subr inp nx ny out

    let mutable ok = true
    let mutable iy = 0
    while ok && iy < ny do
        let mutable ix = 0
        while ok && ix < nx do
            let want = inp.[iy].[ix] + float32 ix + float32 iy
            if out.[iy].[ix] <> want then
                printfn "Error: %f %d %d %f" out.[iy].[ix] ix iy inp.[iy].[ix]
                ok <- false
            ix <- ix + 1
        iy <- iy + 1
    if ok then 0 else 1
