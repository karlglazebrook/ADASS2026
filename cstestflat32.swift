// cstestflat32.swift -- Swift flat [Float] with unsafe buffer pointers and
// Int32 loop indices, so the index sum converts to Float four lanes at a time
// (scvtf.4s) as Keith's C does, instead of two 64-bit lanes. Element loop,
// float32. Wrapping &+ is used for the index sum; the overflow-checked +
// blocks vectorisation at -O.
//    xcrun swiftc -O -o cstestflat32 cstestflat32.swift ; ./cstestflat32 1000 2000 10

func Subr (Input: [Float], Nx: Int, Ny: Int, Output: inout [Float]) {
   Input.withUnsafeBufferPointer { inp in
      Output.withUnsafeMutableBufferPointer { outp in
         let nx32 = Int32(Nx)
         for Iy in 0..<Ny {
            let rowIn = inp.baseAddress! + Iy * Nx
            let rowOut = outp.baseAddress! + Iy * Nx
            let iy32 = Int32(Iy)
            for Ix in 0..<nx32 {
               rowOut[Int(Ix)] = rowIn[Int(Ix)] + Float(Ix &+ iy32)
            }
         }
      }
   }
}
var Nrpt = 1000, Nx = 2000, Ny = 10
let argv = CommandLine.arguments
if argv.count > 1, let v = Int(argv[1]) { Nrpt = v }
if argv.count > 2, let v = Int(argv[2]) { Nx = v }
if argv.count > 3, let v = Int(argv[3]) { Ny = v }
print("Arrays: \(Ny) rows of \(Nx) columns, repeats = \(Nrpt)")

var array = [Float](repeating: 0, count: Nx * Ny)
var output = [Float](repeating: 0, count: Nx * Ny)
for Iy in 0..<Ny { for Ix in 0..<Nx { array[Iy * Nx + Ix] = Float(Nx - Ix + Ny - Iy) } }

for _ in 0..<Nrpt { Subr(Input: array, Nx: Nx, Ny: Ny, Output: &output) }

check: for Iy in 0..<Ny {
   for Ix in 0..<Nx {
      let Expected = array[Iy * Nx + Ix] + Float(Ix + Iy)
      if output[Iy * Nx + Ix] != Expected {
         print("Error at \(Ix),\(Iy) Got \(output[Iy * Nx + Ix]) expected \(Expected)")
         break check
      }
   }
}
