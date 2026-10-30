// csubraw.kt -- Kotlin port of csubraw.cs / csubraw.fs.
//
// Same JVM as Java, different language.  Tests whether Kotlin's
// language abstractions (extension functions, smart casts, etc.)
// cost anything in tight numeric loops.  Spoiler: they shouldn't,
// because kotlinc compiles to plain JVM bytecode and the JIT
// inlines through everything.

fun subr(inp: Array<DoubleArray>, nx: Int, ny: Int, outp: Array<DoubleArray>) {
    for (iy in 0 until ny) {
        val rowIn  = inp[iy]
        val rowOut = outp[iy]
        val fiy    = iy.toDouble()
        for (ix in 0 until nx) {
            rowOut[ix] = rowIn[ix] + ix.toDouble() + fiy
        }
    }
}

fun main(args: Array<String>) {
    val nrpt = if (args.size > 0) args[0].toInt() else 1000
    val nx   = if (args.size > 1) args[1].toInt() else 2000
    val ny   = if (args.size > 2) args[2].toInt() else 10

    val inp  = Array(ny) { DoubleArray(nx) }
    val outp = Array(ny) { DoubleArray(nx) }
    for (iy in 0 until ny)
        for (ix in 0 until nx)
            inp[iy][ix] = (nx - ix + ny - iy).toDouble()

    println("Arrays $nx by $ny count $nrpt")

    repeat(nrpt) { subr(inp, nx, ny, outp) }

    for (iy in 0 until ny) {
        for (ix in 0 until nx) {
            val want = inp[iy][ix] + ix.toDouble() + iy.toDouble()
            if (outp[iy][ix] != want) {
                println("Error: ${outp[iy][ix]} $ix $iy ${inp[iy][ix]}")
                return
            }
        }
    }
}
