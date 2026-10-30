(* csubraw.ml -- OCaml port of csubraw.py / csubraw.rb.
 *
 * OCaml's native compiler (ocamlopt) reaches near-C performance on tight
 * numeric loops with idiomatic code.  We use float array array — OCaml
 * specialises `float array` to be unboxed, so each row is a contiguous
 * block of doubles and Array.unsafe_get/set lower to plain load/store. *)

let subr in_arr nx ny out_arr =
   for iy = 0 to ny - 1 do
      let row_in  = Array.unsafe_get in_arr  iy in
      let row_out = Array.unsafe_get out_arr iy in
      let fiy = float_of_int iy in
      for ix = 0 to nx - 1 do
         Array.unsafe_set row_out ix
            (Array.unsafe_get row_in ix +. float_of_int ix +. fiy)
      done
   done

let () =
   let nrpt = if Array.length Sys.argv > 1 then int_of_string Sys.argv.(1) else 1000 in
   let nx   = if Array.length Sys.argv > 2 then int_of_string Sys.argv.(2) else 2000 in
   let ny   = if Array.length Sys.argv > 3 then int_of_string Sys.argv.(3) else 10 in

   let in_arr  = Array.make_matrix ny nx 0.0 in
   let out_arr = Array.make_matrix ny nx 0.0 in
   for iy = 0 to ny - 1 do
      for ix = 0 to nx - 1 do
         in_arr.(iy).(ix) <- float_of_int (nx - ix + ny - iy)
      done
   done;

   Printf.printf "Arrays %d by %d count %d\n" nx ny nrpt;
   for _ = 1 to nrpt do subr in_arr nx ny out_arr done;

   try
      for iy = 0 to ny - 1 do
         for ix = 0 to nx - 1 do
            if out_arr.(iy).(ix) <> in_arr.(iy).(ix) +. float_of_int ix +. float_of_int iy
            then begin
               Printf.printf "Error: %f %d %d %f\n"
                  out_arr.(iy).(ix) ix iy in_arr.(iy).(ix);
               raise Exit
            end
         done
      done
   with Exit -> ()
