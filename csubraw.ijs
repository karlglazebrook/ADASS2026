NB.                            c s u b r a w . i j s
NB.
NB.   2D array access test in J — the array language.
NB.
NB.   The whole inner kernel is a single expression: y + idxsum
NB.   where idxsum = (i. ny) +/ i. nx is the outer-product-add of two
NB.   index vectors, giving an (ny,nx) matrix of (iy+ix) values.

NB. ----- subr: monadic verb — takes input array y, returns y + idxsum.
subr =: 3 : 0
   shp =. $ y
   y + (i. {. shp) +/ i. {: shp
)

NB. ----- main: J control structures (for_/while./if.) only work inside
NB. explicit definitions, so wrap the whole script body in a verb.
main =: 3 : 0
   ARGV2 =. ARGV , '1000';'2000';'10'
   nrpt =. ". > 2 { ARGV2
   nx   =. ". > 3 { ARGV2
   ny   =. ". > 4 { ARGV2

   ina =. (nx + ny) - (i. ny) +/ i. nx
   out =. 0 $~ ny,nx

   echo 'Arrays ',(":nx),' by ',(":ny),' count ',":nrpt

   for_k. i. nrpt do.
      out =. subr ina
   end.

   expected =. ina + (i. ny) +/ i. nx
   if. 0 < +/ , out ~: expected do.
      echo 'Error: arrays differ'
   end.
   0
)

main 0
exit 0
