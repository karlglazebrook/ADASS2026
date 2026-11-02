// crsrows.rs -- Rust, Keith's Vec<Vec<f32>> layout, indexed form, but the row
// slices are hoisted and the inner loop bound is the row length, so the
// bounds checks are proved away without `unsafe`. Element loop, float32.
//    rustc -C opt-level=3 crsrows.rs -o crsrows ; ./crsrows 1000 2000 10
use std::env;

#[inline(never)]
fn csub(input: &[Vec<f32>], _nx: usize, _ny: usize, output: &mut [Vec<f32>]) {
   for (iy, (row_in, row_out)) in input.iter().zip(output.iter_mut()).enumerate() {
      let row_out = &mut row_out[..row_in.len()];
      for ix in 0..row_in.len() {
         row_out[ix] = row_in[ix] + (ix + iy) as f32;
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
   let mut input = vec![vec![0.0f32; nx]; ny];
   let mut output = vec![vec![0.0f32; nx]; ny];
   for iy in 0..ny { for ix in 0..nx { input[iy][ix] = (nx - ix + ny - iy) as f32; } }
   for _ in 0..nrpt { csub(&input, nx, ny, &mut output); }
   'check: for iy in 0..ny { for ix in 0..nx {
      if output[iy][ix] != input[iy][ix] + (ix + iy) as f32 {
         println!("Error {} {} {} {}", ix, iy, output[iy][ix], input[iy][ix]);
         break 'check;
      } } }
}
