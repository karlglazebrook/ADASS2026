// crsflat32.rs -- as crsflat.rs, but the index sum is narrowed to u32 before
// conversion so it converts four lanes at a time (ucvtf.4s), as C does with int.
// Element loop, float32.
//    rustc -C opt-level=3 crsflat32.rs -o crsflat32 ; ./crsflat32 1000 2000 10
use std::env;

#[inline(never)]
fn csub(input: &[f32], nx: usize, ny: usize, output: &mut [f32]) {
   assert!(input.len() == nx * ny && output.len() == nx * ny);
   for (iy, (row_in, row_out)) in
         input.chunks_exact(nx).zip(output.chunks_exact_mut(nx)).enumerate() {
      for (ix, (i, o)) in row_in.iter().zip(row_out.iter_mut()).enumerate() {
         *o = *i + ((ix + iy) as u32) as f32;
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
   let mut input = vec![0.0f32; nx * ny];
   let mut output = vec![0.0f32; nx * ny];
   for iy in 0..ny { for ix in 0..nx { input[iy * nx + ix] = (nx - ix + ny - iy) as f32; } }
   for _ in 0..nrpt { csub(&input, nx, ny, &mut output); }
   'check: for iy in 0..ny { for ix in 0..nx {
      let k = iy * nx + ix;
      if output[k] != input[k] + (ix + iy) as f32 {
         println!("Error {} {} {} {}", ix, iy, output[k], input[k]);
         break 'check;
      } } }
}
