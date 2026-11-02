// csubf32.kt -- Kotlin float32 variant of csubraw.kt (2026).
// Array<FloatArray> instead of Array<DoubleArray>: same 32-bit element type as
// Keith's csub.java, so Kotlin and Java can be compared like for like.
fun subr(inp: Array<FloatArray>, nx: Int, ny: Int, outp: Array<FloatArray>) {
    for (iy in 0 until ny) {
        val rowIn  = inp[iy]
        val rowOut = outp[iy]
        val fiy    = iy.toFloat()
        for (ix in 0 until nx) {
            rowOut[ix] = rowIn[ix] + ix.toFloat() + fiy
        }
    }
}

fun main(args: Array<String>) {
    val nrpt = if (args.size > 0) args[0].toInt() else 1000
    val nx   = if (args.size > 1) args[1].toInt() else 2000
    val ny   = if (args.size > 2) args[2].toInt() else 10
    val inp  = Array(ny) { FloatArray(nx) }
    val outp = Array(ny) { FloatArray(nx) }
    for (iy in 0 until ny)
        for (ix in 0 until nx)
            inp[iy][ix] = (nx - ix + ny - iy).toFloat()
    println("Arrays $nx by $ny count $nrpt")
    repeat(nrpt) { subr(inp, nx, ny, outp) }
    for (iy in 0 until ny) {
        for (ix in 0 until nx) {
            val want = inp[iy][ix] + (ix + iy).toFloat()
            if (outp[iy][ix] != want) {
                println("Error: ${outp[iy][ix]} $ix $iy ${inp[iy][ix]}")
                return
            }
        }
    }
}
