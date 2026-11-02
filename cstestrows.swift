// cstestrows.swift -- Keith's cstest.swift layout (array of row arrays), but
// the kernel hoists each row once per row (2026 review variant): the input
// row as a let, the output row through withUnsafeMutableBufferPointer, so
// the inner loop does not go through two subscripts and a uniqueness check
// per element. Element loop, float32. Built with -O and -Ounchecked.
//    xcrun swiftc -O -o cstestrows cstestrows.swift ; ./cstestrows 1000 2000 10

func Subr (Input: [[Float]], Nx: Int, Ny: Int, Output: inout [[Float]]) {
   for Iy in 0..<Ny {
      let rowIn = Input[Iy]
      let fy = Float(Iy)
      Output[Iy].withUnsafeMutableBufferPointer { rowOut in
         for Ix in 0..<Nx {
            rowOut[Ix] = rowIn[Ix] + (Float(Ix) + fy)
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

var array = [[Float]](repeating: [Float](repeating: 0, count: Nx), count: Ny)
var output = [[Float]](repeating: [Float](repeating: 0, count: Nx), count: Ny)
for Iy in 0..<Ny { for Ix in 0..<Nx { array[Iy][Ix] = Float(Nx - Ix + Ny - Iy) } }

for _ in 0..<Nrpt { Subr(Input: array, Nx: Nx, Ny: Ny, Output: &output) }

check: for Iy in 0..<Ny {
   for Ix in 0..<Nx {
      let Expected = array[Iy][Ix] + Float(Ix + Iy)
      if output[Iy][Ix] != Expected {
         print("Error at \(Ix),\(Iy) Got \(output[Iy][Ix]) expected \(Expected)")
         break check
      }
   }
}
