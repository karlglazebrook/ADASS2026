#
#                       c n r s u b _ a r m . s
#
#   This is a hand-optimised routine, written mainly as a learning exercise,
#   that provides a plug-in replacement for the following C++ code, running on
#   an ARMv8 processor:
#
#   void subr (float* In[], int Nx, int Ny, float* Out[])
#   {
#      for (int Iy = 0; Iy < Ny; Iy++) {
#         for (int Ix = 0; Ix < Nx; Ix++) {
#            Out[Iy][Ix] = In[Iy][Ix] + Ix + Iy;
#         }
#      }
#   }
#
#   This adds the two index values of each input array element to the contents
#   of the array element and stores the result in the corresponding element of
#   the output array.
#
#   In and Out are assumed to be the addresses of two arrays that hold the
#   addresses of the start of the lines (rows) of two 2D arrays. This is the
#   way access to a 2D array is set up using the scheme in, for example,
#   Numerical Recipes in C. Each of the In and Out arrays will have Ny
#   elements (Ny being the number of rows in the 2D array), and each row
#   will have Nx elements (Nx being the length of each row, ie the number of
#   columns in the array), In practice, when 2D arrays are accessed in this
#   way, the elements of the 2D array will actually be continuous in memory -
#   one row will follow immediately on from the next, and assuming that would
#   make this code marginally simpler, but this code does in fact look at each
#   element of IN and OUT to get the start address of each row.
#
#   This is a plug-in replacement for the routine defined in cnrsub.cpp,
#   intended to be called from the main routine defined in cnrmain.cpp.
#
#  Linking:
#   c++ -c -o cnrsub_arm.o cnrsub_arm.s
#   c++ -o cnrmain -O cnrmain.cpp cnrsub_arm.o
#
#  NOTE:
#   This code uses the ARMv8 instruction set, supported by Apple's M1 and M2
#   processors, and has been tested on an M2 laptop. Its structure is based
#   on the Intel version written in 2019, and most of the comments are an
#   edited version of that version's comments. Obviously the actual code is
#   completely different.
#
#  Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
#
#  History:
#      6th Aug 2022. First properly commented version. KS.
#      4th Dec 2023. Revised some comments. KS.
#
#  Copyright (c) 2022 Knave and Varlet
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#  SOFTWARE.
#
# ------------------------------------------------------------------------------
#
#  Internals:
#
#   This code works by recognising that the numbers that are actually added
#   to each element in In have a simple pattern:
#
#      Ix =  0   1   2   3   4   5   6  .....
#   Iy = 0:  0   1   2   3   4   5   6  .....
#   Iy = 1:  1   2   3   4   5   6   7  .....
#   Iy = 2:  2   3   4   5   6   7   8  .....
#   Iy = 3:  3   4   5   6   7   8   9  .....
#
#   The vector instructions defined for ARMv8 can handle four 32-bit
#   floating point data values at a time. For the first row (Iy=0), the first
#   set of numbers added to the first four data elements are (0,1,2,3) and
#   once those have been done, the values added to the next four are (4,5,6,7)
#   which are each (4,4,4,4) more than the values added to the previous four.
#   This allows a very efficient vector loop through that line.
#
#   For the next line (Iy = 1), the first set of numbers to be added are (1,2,3,
#   4) which is (1,1,1,1) more than the values used at the start of the
#   previous line. That makes it easy to start that fast loop again for the
#   next line.
#
#   Obviously, if Nx is not a multiple of 4, there will be some data elements
#   at the end of the line that cannot be processed using four-element vectors,
#   and these have to be done one by one. But there will only be three at most.
#
#   To speed up the fast inner loop further, this code unrolls the loop to
#   handle four groups of four elements each time through the loop, simply
#   repeating the required sequence four times within the loop body, using
#   four vector registers at a time. This reduces the loop overheads, but
#   means that each pass through the loop handles 16 array elements, and
#   there may be up to 15 that have to be processed one by one. There are
#   some trade-offs here.

# ------------------------------------------------------------------------------

#  This is intended to be called from C++, so has a name that combines 'subr'
#  with an encoded description of the parameter types.

	.section	__TEXT,__text,regular,pure_instructions
	.globl	__Z4subrPPfiiS0_
	.p2align	2
__Z4subrPPfiiS0_:

#  Note the calling convention for passing arguments.
#
#  x0  contains In - the first argument
#  w1  contains Nx - the second argument
#  w2  contains Ny - the third argument
#  x0  contains Out - the fourth argument

#  We aren't going to use any of the registers we're supposed to save
#  and restore if they're going to be changed (x19-x28 incl), so we don't
#  need to save anything locally before proceeding.

#  If either Nx or Ny are zero, quit immediately. Note that although
#  w1 is just a 32-bit part of x1, and the rest of x1 will be zero, we
#  don't do the test for Nx < 1 using x1, as this would be an unsigned
#  comparison. Using w1 makes this a signed comparison  and so will pick
#  up -ve values of Nx. Once we know w1 is positive, we can use x1 for Nx
#  with a clear conscience, as we do later in the code. Ditto for Ny.

    cmp w1, #1                         ; Is Nx less than 1?
    b.lt    Return                     ; If so, quit now.
	cmp	w2, #1                         ; Ditto for Ny.
	b.lt	Return

#  This code has three loops. There is an overall loop through the
#  lines of the input array, that is from Iy = 0 to Iy = Ny - 1.
#  Each time through that loop, we handle a line of the input array.
#  We have a very efficient loop through the elements of that line, which
#  handles the elements sixteen at a time, in four groups of four,
#  using the 128 bit vector registers. If the number of elements in a line
#  (Nx) is not a multiple of 16, then an 'extra' loop is needed to go
#  through those extra elements one by one.

#  Some initial vector values:
#  v11   starts by holding the four integers (0,1,2,4). Each time a line
#        is processed, v11 is incremented by (1,1,1,1).
#  v25   is set to the four integers (1,1,1,1) for the duration of the
#        program.
#  v22   is set to the four floating point values (4.0,4.0,4.0,4.0) for the
#        duration of the program.
#  v16   is set to the four floating point values (16.0,16.0,16.0,16.0) for
#        the duration of the program.
#
#  Note that these values are loaded into the vectors from constants held
#  in a data section. ARMv8 does not have load instructions that can include
#  64-bit addresses - one reason it is an efficient instruction set
#  is that every instruction is a fixed 32-bits. This means that the address
#  of the memory page holding the address has to be loaded into a register
#  which can then be combined with the offset into that page for the address
#  in question. The @PAGE and @PAGEOFF syntax is used by the assembler to
#  work with the linker to make this work properly.
#
#  Also note that the load instructions here refer to the vector registers
#  using their 'q' numbers rather than the 'v' numbers. 'v' refers to the
#  vector as a vector and is used in instructions like 'fadd' where the
#  suffix - eg 'fadd.4s' gives the size of the quantities in the vector ('s'
#  indicates 4 32-bit quantities). 'q' refers to the register as just 128
#  bits and is used for load and store instructions. So the load into q11
#  is also loading values into v11 - they're just different ways of thinking
#  of the same 128 bits of data.

    adrp    x5,ZeroOneTwoThree@PAGE
    ldr     q11,[x5,ZeroOneTwoThree@PAGEOFF]
    adrp    x5,OneOneOneOne@PAGE
    ldr     q25,[x5,OneOneOneOne@PAGEOFF]
    adrp    x5,FourFloatFours@PAGE
    ldr     q22,[x5,FourFloatFours@PAGEOFF]
    adrp    x5,FourFloatSixteens@PAGE
    ldr     q16,[x5,FourFloatSixteens@PAGEOFF]

#   Some initial scalar values
#
#   s1   is set to 1.0 for the duration of the program. This is used in the
#        'extra' loop to increment the float(Ix _ Iy) value after each
#        array element is handled.
#   x6   is set to 'NExtra' - the number of elements in a line that must be
#        handled one by one in the 'extra' loop at the end.
#   x7   is set to the number of times the fast loop through the line will
#        be executed for each line. The number of elements that can be
#        handled 16 at a time in this way is (Nx - NExtra) and so the number
#        of times through the loop is (Nx - NExtra) / 16.

    fmov    s1,#1.0
    and     x6,x1,#15                  ; NExtra = Nx & 15
    sub     x7,x1,x6                   ; Nx - Nextra
    lsr     x7,x7,#4                   ; (Nx - NExtra) / 16

#   This is the start of the loop through all the lines of data.

IyLoop:

#   For each line, a number of values need to be set up in preparation
#   for the fast loop. What happens in the fast loop is that the next
#   sixrteen data values will be loaded into 4 of the vector registers
#   (v17,v18,v19 and v20). We pre-calculate the floating point values that
#   need to be added into each, and have these set in v7,v8,v9 and v10
#   respectively. At the start of each line, v11 contains the four
#   integer values that need to be added to the first four elements of
#   the line. The initial set of incremental values to be added to each
#   of the four vectors are calculated from the value in v7 and stored
#   in v7,v8,v9,v10. Remember each of the four values held in v22 have been
#   set to 4.0. Ready for the next line, where each starting value will
#   be one more, increment each integer in v11 by 1.

    scvtf.4s    v7,v11              ; Convert initial ints to float in v11
    fadd.4s     v8,v7,v22           ; Add 4.0 to each to get the values for
    fadd.4s     v9,v8,v22           ; the next set of four, and then again
    fadd.4s     v10,v9,v22          ; for the next two sets.
    add.4s      v11,v11,v25         ; Add 1 to each of the int values in v11

#   X0 holds In, the address of the array of addresses holding that start of
#   each input line. We load the address of the start of the current line
#   into x14, and increment x0 by 8 to point it to the next 64-bit element
#   in In, ready for to handle the next line. In the fast loop, we can load
#   two vectors at a time using the ldp instruction. We will load the first
#   pair from the address now in x14. The address from which we load the
#   second pair will be 32bytes further on. We set that address into x15,
#   which we will use for the second ldp instruction. Ditto for x3, which
#   holds Out, so x16 points to the start of the output data for this line,
#   and x17 holds this address plus 32.

    ldr         x14,[x0],#8
    ldr         x16,[x3],#8
    add         x15,x14,#32
    add         x17,x16,#32

#   We will use x13 as the loop counter through the fast loop. x7 has the
#   number of times we want to execute the loop, so we copy that into x13
#   since we'll decrement it each time through the loop. If the count is
#   zero - which will happen if there are fewer than 16 data elements in
#   each line, we skip straight to the 'Extra' loop to deal with them.

    mov         x13,x7              ; mov doesn't set flags, so we need
    cbz         x13,Extras          ; a compare and branch test here.

#   This is the fast loop through the line, 16 elements being handled
#   each time through, using 4 vectors (v17,v18,v19,v20) each holding
#   four elements. At the start, v7,v8,v9,v10 hold the Ix+Iy values
#   (as floats) for each of these v17-v20 vectors. We add those Ix+Iy
#   values to the four vectors, and increment each of the v7-v10 vectors
#   by the four 16.0 values held in v16, which sets them up ready for the
#   next loop. Then we store the incremented value in the output array,
#   decrement the loop counter in x13, and keep on repeating the loop
#   until x13 hits zero.
#
#   At the start of the loop, x14 holds the address of the start of the line,
#   from which we load the first 8 data values into q17,q18. Similarly,
#   x15 holds the address of the next 8 data elements (32 bytes ahead, so
#   x15 = x14 + 32), from which we load into q19,q20. After that we increment
#   each of the two address registers by 64, which can be done all in the
#   ldp instructions, using the post-increment syntax shown here. As explained
#   earlier, loading into q17 sets v17, as they both designate the same
#   vector register. The same scheme applies at the end of the loop to the
#   x16 and x17 registers, which hold the equivalent addresses in the Out
#   array.

IxLoop:
    ldp         q17,q18,[x14],#64       ; load b18,v18
    ldp         q19,q20,[x15],#64       ; and v19,v20
    fadd.4s     v17,v17,v7              ; Add Ix+Iy values to them
    fadd.4s     v18,v18,v8
    fadd.4s     v19,v19,v9
    fadd.4s     v20,v20,v10
    fadd.4s     v7,v7,v16               ; Increment those Ix+Iy values
    fadd.4s     v8,v8,v16               ; ready for the next loop
    fadd.4s     v9,v9,v16
    fadd.4s     v10,v10,v16
    stp         q17,q18,[x16],#64       ; Store the incremented values
    stp         q19,q20,[x17],#64
    subs        x13,x13,#1              ; Decrement loop counter
    b.ne        IxLoop                  ; and go round again

#   This is where we handle the 'extra' data values in the line that
#   couldn't be handled 16 at a time by the fast loop. At this point:
#   x6     Has the number of extra values to be handled
#   x14    has the address of the first extra data value in the In array
#   x16    has the address of the corresponding data value n the Out array
#   x9     will be used as the loop index
#   s1     has the constant value 1.0
#   s7     has the first Ix+Iy value to be added.
#   Note that s7 has this first value, because s7 refers to the first
#   floating point value in the vector v7, which now holds the next four
#   Ix+Iy values to be added into the next 4 data elements in the line.
#   This is the case because v7 is set to the relevant values at the
#   start of the preparation for handling the line (so has these even if
#   there are no passes through the fast loop) and has been incremented
#   as needed during any passes through the fast loop.

Extras:
    cbz         x6,EndXLoop             ; Check in case there are no extras
    mov         x9,x6                   ; Set loop counter initial value
ExtraLoop:
    ldr         s6,[x14],#4             ; Load data value
    fadd        s6,s6,s7                ; Increment it by Ix+Iy
    fadd        s7,s7,s1                ; Increment Ix+Iy by 1
    str         s6,[x16],#4             ; Store incremented value
    subs        x9,x9,#1                ; Decrement loop counter
    b.ne        ExtraLoop               ; and carry on.

#   This is the end of the loop through one line of the data.

EndXLoop:
    subs        x2,x2,#1                ; Decrement loop counter
    b.ne        IyLoop                  ; and handle next line if any left.

#   Returning to the caller is easy. We haven't used any of the registers
#   we're supposed to save, so all we have to do is return immediately.
#   We don't return a result - we're emulating a C++ void function.

Return:
	ret

#   Thise section contains the various constants we load up into registers
#   during the running of the code.

    .section    __TEXT,__literal16,16byte_literals
    .p2align    4
ZeroOneTwoThree:
    .long   0,1,2,3
OneOneOneOne:
    .long   1,1,1,1
FourFloatFours:
    .float  4.0,4.0,4.0,4.0
FourFloatSixteens:
    .float  16.0,16.0,16.0,16.0

# ------------------------------------------------------------------------------
#
#                  P r o g r a m m i n g    N o t e s
#
#  O  I've been told I tend to over-comment my code. That's not the case,
#     but I have perhaps overdone things a bit in this case. That's because
#     I used this coding exercise as a way of learning ARM assembler, so this
#     code is partly detailed notes to myself. It's also because I suspect that
#     most potential readers of this (if any) are looking at it as people
#     interested in the genral comparison of programming languages it forms
#     part of, rather than as existing experts in ARM assembler.
#
#  O  The main take-away from this exercise, for me, was how good the code
#     generated by the Clang C++ compiler was. It's really almost impossible
#     to beat it by hand-coding in assembler.
#
#  O  This code does beat the Clang compiler - at least in the version I
#     was using (13.1.6) - but only by maybe 10% and it does it to some
#     extent by cheating. The general structure of the code here follows that
#     generated by Clang (that's how to learn - look at what the compiler
#     does) but it assumes that I can start by working out the Ix+Iy values
#     as integers at the start of each line, but can then convert these to
#     floats and work through the line adding 1.0 to each float for each
#     data element in the line. Clang is more precise, using integers as it
#     increments along the line, and only then converting to floats. That
#     means this code saves on the integer->float conversions as it procedes
#     along the line. This is cheating, becuase this relies on being able to
#     represent the integer values exacly in floating point, and this falls
#     down for 32-bit IEEE floats once Ix+Iy > 16,777,217. Which is big but
#     not unimaginably big. If I really cared, I'd test for this condition
#     and use a different loop if it wasn't met, thereby getting that extra
#     10% speed when available, but also working for all array sizes.
#
#  O  My original version of this code only handled 8 elements at a time in
#     the fast loop, using just one ldp instruction to load two vectors at
#     a time. Using two sets gives a significant improvement in speed - I
#     think about 20% from memory - and that's what Clang does. I didn't
#     bother to experiment with using more, because I figured Clang probably
#     knew what it was doing, and previous versions of this code for Intel
#     had shown that diminishing returns cut in very quickly after the initial
#     gain. And it gets complicated very quickly. Feel free to experiment!
#
#  O  My original loop with 8 elements at a time used just one vector register
#     to hold the values by which I incremented the Ix+Iy values. So I would
#     set this up for the first four data element at the start of the line,
#     would apply it to those elements, then add a vector (4.0,4.0,4.0,4.0)
#     to it so it was ready for the next four elements. I was surprised to
#     find this was half the speed of the Clang code. In this scheme the loop
#     body was essentially:
#
#     ldp         q17,q18,[x14],#32       ; Load input values into v17,v18
#     fadd.4s     v17,v17,v7              ; Add Ix+Iy values in v7 to v17
#     fadd.4s     v7,v7,v16               ; Increment Ix+Iy values each by 4.0
#     fadd.4s     v18,v18,v7              ; Add new Ix+Iy values to v18
#     fadd.4s     v7,v7,v16               ; Increment Ix+Iy values each by 4.0
#     stp         q17,q18,[x16],#32       ; Store the incremented values
#
#     But it turns out this gets in the way of out-of-order execution. It
#     doesn't allow the processor to overlap instructions. Because v7 is
#     incremented in one instruction and then its new value is used in the
#     next instruction to increment v18, the processor has to wait for
#     first instruction to finish before it can start the next. This makes
#     much more difference than I'd expected! Changing this to use two
#     registers to hold the increment values, and incrementing each of
#     these by 8.0 after being used, makes the loop look like:
#
#     ldp         q17,q18,[x14],#32       ; Load input values into v17,v18
#     fadd.4s     v17,v17,v7              ; Add Ix+Iy values to v17
#     fadd.4s     v7,v7,v16               ; Increment Ix+Iy values each by 8.0
#     fadd.4s     v18,v18,v8              ; Add alternate Ix+Iy values to v18
#     fadd.4s     v8,v8,v16               ; Increment Ix+Iy values each by 8.0
#     stp         q17,q18,[x16],#32       ; Store the incremented values
#
#     and this runs noticeably faster, even though it's the same number of
#     the same type of instructions. Compilers know this sort of thing,
#     which is why it's so hard to beat them nowadays.(I typed these example
#     code fragments in as comments, and haven't actually run them - I may
#     have made typos; the basic point is valid.)
#
#     The final code uses four sets of incrmenting values in four separate
#     registers for just this reason.

