// cstestflat.swift -- Swift with one flat array (2026).
//
// Keith's cstest.swift unchanged except for the storage: the two arrays are
// single contiguous [Float] of Ny*Nx elements, indexed Iy*Nx + Ix, instead of
// arrays of row arrays. In cstest.swift each row is a separate
// reference-counted, copy-on-write buffer reached through a second array;
// this tests how much of Swift's 18x at -O is that layout rather than the
// language. Built with -O and -Ounchecked, as cstest.swift is.

func Subr (Input: [Float], Nx: Int, Ny : Int, Output: inout [Float]) {
   for Iy in 0...Ny-1 {
      for Ix in 0...Nx-1 {
         Output[Iy * Nx + Ix] = Input[Iy * Nx + Ix] + Float(Ix + Iy)
      }
   }
}

var Nrpt:Int = 1000
var Nx:Int = 2000;
var Ny:Int = 10;
if (CommandLine.argc > 1) {
    let argStr = CommandLine.arguments[1]
    if let argInt = Int(argStr) { Nrpt = argInt }
}
if (CommandLine.argc > 2) {
    let argStr = CommandLine.arguments[2]
    if let argInt = Int(argStr) { Nx = argInt }
}
if (CommandLine.argc > 3) {
    let argStr = CommandLine.arguments[3]
    if let argInt = Int(argStr) { Ny = argInt }
}
print("Arrays: \(Ny) rows of \(Nx) columns, repeats = \(Nrpt)")

var array = Array(repeating:Float(), count:Nx * Ny)
var output = Array(repeating:Float(), count:Nx * Ny)
for Iy in 0...Ny-1 {
  for Ix in 0...Nx-1 {
      array[Iy * Nx + Ix] = Float(Nx - Ix + Ny - Iy)
  }
}

for _ in 0...Nrpt-1 {
   Subr(Input: array,Nx: Nx,Ny: Ny,Output: &output)
}

check:
for Iy in 0...Ny-1 {
   for Ix in 0...Nx-1 {
      let Expected = array[Iy * Nx + Ix] + Float(Ix + Iy)
      if (output[Iy * Nx + Ix] != Expected) {
          print("Error at \(Ix),\(Iy) Got \(output[Iy * Nx + Ix]) expected \(Expected)")
          break check
      }
   }
}
