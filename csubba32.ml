(* csubba32.ml -- OCaml float32 variant: Bigarray.Array1 of float32 (flat,
   row-major, C layout), the only unboxed 32-bit float storage in stock OCaml.
   Loads widen to double, the add is in double, the store narrows: the same
   arithmetic as Keith's C kernel compiled without -ffast-math promotion, half
   the memory traffic of csubraw.ml.  Row base index hoisted out of the inner loop. *)
open Bigarray
type mat = (float, float32_elt, c_layout) Array1.t

let subr (in_arr : mat) nx ny (out_arr : mat) =
   for iy = 0 to ny - 1 do
      let base = iy * nx in
      let fiy = float_of_int iy in
      for ix = 0 to nx - 1 do
         Array1.unsafe_set out_arr (base + ix)
            (Array1.unsafe_get in_arr (base + ix) +. float_of_int ix +. fiy)
      done
   done

let () =
   let nrpt = if Array.length Sys.argv > 1 then int_of_string Sys.argv.(1) else 1000 in
   let nx   = if Array.length Sys.argv > 2 then int_of_string Sys.argv.(2) else 2000 in
   let ny   = if Array.length Sys.argv > 3 then int_of_string Sys.argv.(3) else 10 in
   let in_arr  : mat = Array1.create float32 c_layout (nx * ny) in
   let out_arr : mat = Array1.create float32 c_layout (nx * ny) in
   Array1.fill out_arr 0.0;
   for iy = 0 to ny - 1 do
      for ix = 0 to nx - 1 do
         in_arr.{iy * nx + ix} <- float_of_int (nx - ix + ny - iy)
      done
   done;
   Printf.printf "Arrays %d by %d count %d\n" nx ny nrpt;
   for _ = 1 to nrpt do subr in_arr nx ny out_arr done;
   try
      for iy = 0 to ny - 1 do
         for ix = 0 to nx - 1 do
            if out_arr.{iy * nx + ix} <> in_arr.{iy * nx + ix} +. float_of_int ix +. float_of_int iy
            then begin
               Printf.printf "Error: %f %d %d %f\n" out_arr.{iy * nx + ix} ix iy in_arr.{iy * nx + ix};
               raise Exit
            end
         done
      done
   with Exit -> ()
