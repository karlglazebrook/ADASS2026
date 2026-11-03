// Rust with a 2D Grid type: one flat Vec<f32> behind a two-index subscript,
// the analogue of cstestgrid.swift. Safe, bounds-checked indexing.
use std::env;
use std::ops::{Index, IndexMut};

struct Grid { nx: usize, ny: usize, data: Vec<f32> }
impl Grid { fn new(nx: usize, ny: usize) -> Grid { Grid { nx, ny, data: vec![0.0; nx * ny] } } }
impl Index<(usize, usize)> for Grid {
   type Output = f32;
   fn index(&self, (iy, ix): (usize, usize)) -> &f32 { &self.data[iy * self.nx + ix] }
}
impl IndexMut<(usize, usize)> for Grid {
   fn index_mut(&mut self, (iy, ix): (usize, usize)) -> &mut f32 { &mut self.data[iy * self.nx + ix] }
}

#[inline(never)]
fn csub(input: &Grid, output: &mut Grid) {
   for iy in 0..input.ny {
      for ix in 0..input.nx {
         output[(iy, ix)] = input[(iy, ix)] + (ix + iy) as f32;
      }
   }
}

fn main() {
   let mut nrpt = 1000; let mut nx = 2000; let mut ny = 10;
   let args: Vec<String> = env::args().collect();
   if args.len() > 1 { if let Ok(n) = args[1].parse::<usize>() { nrpt = n } }
   if args.len() > 2 { if let Ok(n) = args[2].parse::<usize>() { nx = n } }
   if args.len() > 3 { if let Ok(n) = args[3].parse::<usize>() { ny = n } }
   println!("Arrays have {} rows of {} columns, repeats = {}", ny, nx, nrpt);
   let mut input = Grid::new(nx, ny);
   let mut output = Grid::new(nx, ny);
   for iy in 0..ny { for ix in 0..nx { input[(iy, ix)] = (nx - ix + ny - iy) as f32; } }
   for _ in 0..nrpt { csub(&input, &mut output); }
   'check: for iy in 0..ny { for ix in 0..nx {
      if output[(iy, ix)] != input[(iy, ix)] + (ix + iy) as f32 {
         println!("Error {} {}", ix, iy); break 'check; } } }
}
