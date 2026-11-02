(* csubmapi.ml -- OCaml, the idiomatic immutable form: Array.map / Array.mapi
   allocate a fresh float array array each call.  Whole-array style. *)
let subr in_arr =
   Array.mapi (fun iy row ->
      let fiy = float_of_int iy in
      Array.mapi (fun ix v -> v +. float_of_int ix +. fiy) row) in_arr

let () =
   let nrpt = if Array.length Sys.argv > 1 then int_of_string Sys.argv.(1) else 1000 in
   let nx   = if Array.length Sys.argv > 2 then int_of_string Sys.argv.(2) else 2000 in
   let ny   = if Array.length Sys.argv > 3 then int_of_string Sys.argv.(3) else 10 in
   let in_arr = Array.init ny (fun iy -> Array.init nx (fun ix -> float_of_int (nx - ix + ny - iy))) in
   Printf.printf "Arrays %d by %d count %d\n" nx ny nrpt;
   let out_arr = ref (Array.make_matrix ny nx 0.0) in
   for _ = 1 to nrpt do out_arr := subr in_arr done;
   let out_arr = !out_arr in
   try
      for iy = 0 to ny - 1 do
         for ix = 0 to nx - 1 do
            if out_arr.(iy).(ix) <> in_arr.(iy).(ix) +. float_of_int ix +. float_of_int iy
            then begin
               Printf.printf "Error: %f %d %d %f\n" out_arr.(iy).(ix) ix iy in_arr.(iy).(ix);
               raise Exit
            end
         done
      done
   with Exit -> ()
