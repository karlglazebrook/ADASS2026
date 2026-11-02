# ctestlst.tcl -- Tcl with nested lists instead of a string-keyed array
# (2026 review variant of ctest.tcl).  Rows are Tcl lists reached with
# lindex, written with lset (in place while the list is unshared); braced
# expr throughout.
proc subr { inary nx ny outary } {
   upvar $inary in
   upvar $outary out
   for {set iy 0} {$iy < $ny} {incr iy} {
      set rin [lindex $in $iy]
      for {set ix 0} {$ix < $nx} {incr ix} {
         lset out $iy $ix [expr {[lindex $rin $ix] + $ix + $iy}]
      }
   }
}
set ny 10
set nx 2000
set nrpt 100
if { $argc > 0 } { set nrpt [lindex $argv 0] }
if { $argc > 1 } { set nx [lindex $argv 1] }
if { $argc > 2 } { set ny [lindex $argv 2] }
set in {}
set out {}
for {set iy 0} {$iy < $ny} {incr iy} {
   set rin {}
   set rout {}
   for {set ix 0} {$ix < $nx} {incr ix} {
      lappend rin [expr {double($nx - $ix + $ny - $iy)}]
      lappend rout 0.0
   }
   lappend in $rin
   lappend out $rout
}
puts "Arrays $ny rows by $nx columns, repeat = $nrpt"
for {set loop 0} { $loop < $nrpt} {incr loop} { subr in $nx $ny out }
set error 0
for {set iy 0} {$iy < $ny} {incr iy} {
   for {set ix 0} {$ix < $nx} {incr ix} {
      if { [lindex $out $iy $ix] != ([lindex $in $iy $ix] + $ix + $iy) } {
         set error 1
         puts "Error: [lindex $out $iy $ix] $ix $iy [lindex $in $iy $ix]"
         break
      }
   }
   if { $error } { break }
}
exit
