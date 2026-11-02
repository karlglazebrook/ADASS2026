// cstestbuf.swift -- Swift, one flat [Float], kernel on unsafe buffer pointers
// (2026 review variant). The idiomatic Swift way to run a hot numeric loop:
// withUnsafe(Mutable)BufferPointer gives the storage once per call, the row
// pointers are formed once per row, and the index sum is Float(Ix) + Float(Iy)
// so there is no overflow-checked integer add in the loop. Unlike
// cstestflat.swift this vectorises at plain -O. Element loop, float32.
//    xcrun swiftc -O -o cstestbuf cstestbuf.swift ; ./cstestbuf 1000 2000 10

func Subr (Input: [Float], Nx: Int, Ny: Int, Output: inout [Float]) {
   Input.withUnsafeBufferPointer { inp in
      Output.withUnsafeMutableBufferPointer { outp in
         for Iy in 0..<Ny {
            let rowIn = inp.baseAddress! + Iy * Nx
            let rowOut = outp.baseAddress! + Iy * Nx
            let fy = Float(Iy)
            for Ix in 0..<Nx {
               rowOut[Ix] = rowIn[Ix] + (Float(Ix) + fy)
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
