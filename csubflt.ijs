NB.                            c s u b f l t . i j s
NB.
NB.   2D array access test in J, whole-array form, on FLOAT data (2026).
NB.
NB.   csubraw.ijs builds ina from integer dimensions and i. arrays, so it
NB.   is an int64 test (J's integer add is overflow-checked). Here the input
NB.   is offset by 0.5, as in the Dyalog files, so ina and out are 64-bit
NB.   floats (3!:0 gives 8). The kernel is unchanged: y + the addition
NB.   table (i. ny) +/ i. nx, built on every call.
subr =: 3 : 0
   shp =. $ y
   y + (i. {. shp) +/ i. {: shp
)
main =: 3 : 0
   ARGV2 =. ARGV , '1000';'2000';'10'
   nrpt =. ". > 2 { ARGV2
   nx   =. ". > 3 { ARGV2
   ny   =. ". > 4 { ARGV2
   ina =. 0.5 + (nx + ny) - (i. ny) +/ i. nx
   out =. 0.5 $~ ny,nx
   echo 'Arrays ',(":nx),' by ',(":ny),' count ',":nrpt
   for_k. i. nrpt do.
      out =. subr ina
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
