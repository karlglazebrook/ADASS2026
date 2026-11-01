// cstestgrid.swift -- Swift with a 2D grid type (2026).
//
// The idiomatic fix for Swift's lack of rectangular arrays: a small struct
// that keeps one flat [Float] (as in cstestflat.swift) but gives it a
// two-index subscript, so the kernel reads Output[Iy, Ix] like Fortran or
// numpy. The question is whether the optimiser inlines the subscript away
// and matches the hand-indexed flat array. Built with -O and -Ounchecked.

struct Grid {
   let Nx: Int
   let Ny: Int
   var Data: [Float]

   init(Nx: Int, Ny: Int) {
      self.Nx = Nx
      self.Ny = Ny
      Data = Array(repeating: Float(), count: Nx * Ny)
   }

   subscript(Iy: Int, Ix: Int) -> Float {
      get { return Data[Iy * Nx + Ix] }
      set { Data[Iy * Nx + Ix] = newValue }
   }
}

func Subr (Input: Grid, Nx: Int, Ny : Int, Output: inout Grid) {
   for Iy in 0...Ny-1 {
      for Ix in 0...Nx-1 {
         Output[Iy, Ix] = Input[Iy, Ix] + Float(Ix + Iy)
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

var array = Grid(Nx: Nx, Ny: Ny)
var output = Grid(Nx: Nx, Ny: Ny)
for Iy in 0...Ny-1 {
  for Ix in 0...Nx-1 {
      array[Iy, Ix] = Float(Nx - Ix + Ny - Iy)
  }
}

for _ in 0...Nrpt-1 {
   Subr(Input: array,Nx: Nx,Ny: Ny,Output: &output)
}

check:
for Iy in 0...Ny-1 {
   for Ix in 0...Nx-1 {
      let Expected = array[Iy, Ix] + Float(Ix + Iy)
      if (output[Iy, Ix] != Expected) {
          print("Error at \(Ix),\(Iy) Got \(output[Iy, Ix]) expected \(Expected)")
          break check
      }
   }
}
