// fs_while_proj/Program.fs -- F# with explicit while loops (2026 variant).
//
// Same double[][] data as fs_proj. F#'s `for ix in 0 .. nx - 1` compiles to a
// do/while loop whose exit test is `ix <> nx`; RyuJIT's loop cloning (which
// removes the bounds checks) only recognises `<` style tests, so the fs_proj
// inner loop keeps two range checks per element. A `while ix < nx` loop gives
// the JIT the shape it wants, as C#'s `for` does.
module CsubRaw

let subr (inp: float[][]) (nx: int) (ny: int) (out: float[][]) : unit =
    let mutable iy = 0
    while iy < ny do
        let rowIn  = inp.[iy]
        let rowOut = out.[iy]
        let fiy    = float iy
        let mutable ix = 0
        while ix < nx do
            rowOut.[ix] <- rowIn.[ix] + float ix + fiy
            ix <- ix + 1
        iy <- iy + 1

[<EntryPoint>]
let main args =
    let nrpt = if args.Length > 0 then int args.[0] else 1000
    let nx   = if args.Length > 1 then int args.[1] else 2000
    let ny   = if args.Length > 2 then int args.[2] else 10
    let inp  = Array.init ny (fun _ -> Array.zeroCreate<float> nx)
    let out  = Array.init ny (fun _ -> Array.zeroCreate<float> nx)
    for iy in 0 .. ny - 1 do
        for ix in 0 .. nx - 1 do
            inp.[iy].[ix] <- float (nx - ix + ny - iy)
    printfn "Arrays %d by %d count %d" nx ny nrpt
    for _ in 1 .. nrpt do subr inp nx ny out
    let mutable ok = true
    let mutable iy = 0
    while ok && iy < ny do
        let mutable ix = 0
        while ok && ix < nx do
            let want = inp.[iy].[ix] + float ix + float iy
            if out.[iy].[ix] <> want then
                printfn "Error: %f %d %d %f" out.[iy].[ix] ix iy inp.[iy].[ix]
                ok <- false
            ix <- ix + 1
        iy <- iy + 1
    if ok then 0 else 1
