NB.                            c s u b l o o p . i j s
NB.
NB.   2D array access test in J, element-by-element loop (2026): Keith's
NB.   kernel as explicit for_ loops, fetching each element with { and
NB.   writing it with amend (}). This is the form J is not designed for;
NB.   csubraw.ijs / csubflt.ijs are the one-line array form. The input is
NB.   offset by 0.5 so the arrays are floats (J keeps whole numbers as ints).
subr =: 4 : 0
   'ny nx' =. $ x
   out =. y
   for_iy. i. ny do.
      for_ix. i. nx do.
         out =. (((< iy, ix) { x) + ix + iy) (< iy, ix) } out
      end.
   end.
   out
)
main =: 3 : 0
   ARGV2 =. ARGV , '100';'2000';'10'
   nrpt =. ". > 2 { ARGV2
   nx   =. ". > 3 { ARGV2
   ny   =. ". > 4 { ARGV2
   ina =. 0.5 + (nx + ny) - (i. ny) +/ i. nx
   out =. 0.5 $~ ny,nx
   echo 'Arrays ',(":nx),' by ',(":ny),' count ',":nrpt
   for_k. i. nrpt do.
      out =. ina subr out
   end.
   expected =. ina + (i. ny) +/ i. nx
   if. 0 < +/ , out ~: expected do.
      echo 'Error: arrays differ'
      exit 1
   end.
   0
)
main 0
exit 0
