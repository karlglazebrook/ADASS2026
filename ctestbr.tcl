# ctestbr.tcl -- ctest.tcl with braced expr (2026 review variant).
# In Tcl an unbraced  expr $a + $b  is substituted first and then parsed as
# a string every time it runs; braced  expr {$a + $b}  is byte-compiled
# once.  Nothing else changes: same array(iy,ix) storage.
proc subr { inary nx ny outary } {
   upvar $inary in
   upvar $outary out
   for {set iy 0} {$iy < $ny} {incr iy} {
      for {set ix 0} {$ix < $nx} {incr ix} {
         set out($iy,$ix) [expr {$in($iy,$ix) + $ix + $iy}]
      }
   }
}
set ny 10
set nx 2000
set nrpt 100
if { $argc > 0 } { set nrpt [lindex $argv 0] }
if { $argc > 1 } { set nx [lindex $argv 1] }
if { $argc > 2 } { set ny [lindex $argv 2] }
for {set iy 0} {$iy < $ny} {incr iy} {
   for {set ix 0} {$ix < $nx} {incr ix} {
      set in($iy,$ix) [expr {double($nx - $ix + $ny - $iy)}]
      set out($iy,$ix) 0.0
   }
}
puts "Arrays $ny rows by $nx columns, repeat = $nrpt"
for {set loop 0} { $loop < $nrpt} {incr loop} { subr in $nx $ny out }
set error 0
for {set iy 0} {$iy < $ny} {incr iy} {
   for {set ix 0} {$ix < $nx} {incr ix} {
      if { $out($iy,$ix) != ($in($iy,$ix) + $ix + $iy) } {
         set error 1
         puts "Error: $out($iy,$ix) $ix $iy $in($iy,$ix)"
         break
      }
   }
   if { $error } { break }
}
exit
