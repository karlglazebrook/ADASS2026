#!/usr/bin/env python

#                              R u n . p y
#
#  Summary:
#     Test framework for 2D array access tests.
#
#  Introduction:
#     This is a test program written as part of a study into how well different
#     languages handle accessing elements of 2D rectangular arrays - the sort of
#     thing that are common in astronomy and similar scientific disciplines.
#     This program runs all the various test programs written for the study
#     automatically, building any that need to be built - ie those written in
#     compiled languages like C or Fortran - and timing them as they run.
#
#  Invocation:
#     ./Run.py ntests nx ny
#
#     or, depending on how Python and/or Python3 have been set up:
#
#     python Run.py ntests nx ny          or
#     python3 Run.py ntests nx ny
#
#     where
#        ntests  is how many times the full test set is repeated - default 1.
#        nx      is the number of columns in the array tested - default 2000.
#        ny      is the number of rows in the array tested - default 10.
#
#     This assumes that all the code files for the various test programs are
#     in the default directory. It also assumes that the various compilers
#     and interpreters have been installed so that the various commands
#     such as 'c++', 'g++', 'julia' etc all work. (They have to work when
#     run in a sub-process without a shell, as the commands are run through
#     the Python subprocess module. This is more restrictive than it may look,
#     as it generally means that commands defined as aliases - eg if 'julia' has
#     been aliased to '<some directory>/julia' - these will not work. In general
#     the solution is to make sure that, in this case, <some directory> is in
#     the default path.)
#
#  Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
#
#  History:
#     28th Aug 2019. First properly commented version. KS.
#     14th Sep 2019. Added PCL and Rust tests, and two more Python tests.
#                    All tests now have a single baseline run with one
#                    repeat to try to allow for startup and checking
#                    overheads. KS.
#     24th Oct 2019. Added the tests Python3npNumba (which uses the numba jit
#                    compiler to speed up the raw numpy array test) and
#                    JuliaInt32 which tweaks the Julia code to get up to C++
#                    speeds. KS.
#     29th Oct 2019. Added the tests RustO3nativeIter and RustO3nativeUnsafe,
#                    which represent more efficient ways of coding the test
#                    program in Rust (using iterators and 'unsafe', ie unchecked
#                    access, respectively). KS.
#
#  Copyright (c) 2019 Knave and Varlet
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
#  This code should run under either python 2 or python 3, so long as
#  the python 2 version supports the "from __future__ import" used here.
#  It has been tested under 2.7 and 3.6.
#

from __future__ import (print_function,division,absolute_import)

import subprocess
import datetime
import time
import sys
import numpy

# Note: this script expects PATH and a few tool-specific environment
# variables (RUSTUP_HOME, CARGO_HOME, CPLUS_INCLUDE_PATH, DOTNET_ROOT,
# OCAMLLIB) to be set up correctly for the 29-language 2026 suite.  All
# of that bootstrap lives in ../run-benchmarks.sh in the parent
# directory.  Run via:    ./run-benchmarks.sh
# rather than calling Run.py directly.

# ------------------------------------------------------------------------------

#                      E x e c u t e  C o m m a n d
#
#  ExecuteCommand() is a utility that runs a single command, waiting for it
#  to cpmplete. It returns a tuple, (Status,Output,Errors) where Status is
#  None if the command completed OK, or an error string - which includes
#  the command itself - if it completed with bad status, Output is what was
#  written to standard output by the command, and Error is what was written
#  to standard error by the command. Command should be a single string or a
#  list of strings, but if it is a single string it will be split (using
#  spaces as delimiters) into a list, rather than being passed to a shell to
#  interpret.
#
#  This is packaged as a separate routine because it's actually tricky to
#  get right, particularly using the subprocess module. (The recent routine
#  subprocess.call() does most of this, but only dates from Python 3.5. Also
#  note that a lot of the things this might be used for, like extracting
#  archives using tar, can be done using ordinary python modules.)
#
#  This routine is based on the RunCommand() code from AdassChecks.py in the
#  package written to process ADASS conference papers, but this returns the
#  output and error streams from the subprocess as well as just the status.
#

def ExecuteCommand (Command) :

   Status = None
   
   #  We don't want to use a shell to interpret the command, since that
   #  has security implications (if Command is built up using outside input
   #  nasty stuff can be embedded in it), so we need to pass Popen() an
   #  argument list rather than a command. (Note: in Python 2 the test
   #  should really be for basestring rather than str, as this misses
   #  unicode strings, but basestring isn't defined in Python 3). This
   #  isn't really important if all the strings being pased to this routine
   #  are embedded in the calling code, but if this is extracted and used
   #  as a general purpose routine it might matter.
   
   if (isinstance(Command,str)) : CommandList = Command.split()
   else : CommandList = Command
   
   #  Run the command, reading what it writes to standard output and standard
   #  error through pipes. The utf-8 decode step is because in Python 3
   #  Proc.communicate() returns bytes in UTF-8 rather than str strings,
   #  whereas Python2 doesn't make that distinction.
   
   Output = ""
   Errors = ""
   Result = ""
   try :
      Proc = subprocess.Popen(CommandList,stdout=subprocess.PIPE, \
                                                   stderr=subprocess.PIPE)
      (Output,Errors) = Proc.communicate()
      Output = Output.decode('utf-8')
      Errors = Errors.decode('utf-8')
      Proc.stdout.close()
      Proc.stderr.close()
      Result = Proc.wait()
      if (Result != 0) :
         Status = "Error executing '" + str(Command) + "'"
   except KeyboardInterrupt :
   
      #  Normally, ctrl-C would only terminate the subprocess. Here we
      #  trap it and terminate the whole program, which is probably what
      #  was intended.
      
      sys.exit(0)
   except :
      Status = "Error executing '" + str(Command) + "'"

   return (Status,Output,Errors)

# ------------------------------------------------------------------------------

#                   B u i l d  A n d  T i m e  P r o g r a m
#
#  This routine handles the building and running of one of the various test
#  programs. This assumes that building the program requires at most two
#  steps, and running it only requires a single command with the three
#  parameters giving the size of the arrays to use (as Nx by Ny) and the
#  number of repeats. A Python script does not require any build step,
#  while a C++ program may require two compilation steps, one for the
#  subroutine that does most of the work and one to build the main program.
#  If no build staps are required, the build strings should be null strings.
#  This routine will build the program by executing the build commands, then
#  will run it, putting together a command line formed from the command
#  string and the parameters and timing the execution of that line. If a
#  non-null cleanup command is passed, it will then run that to remove any
#  intermediate files, such as the built object files and executable. It
#  returns the total time taken for the test in seconds, together with
#  a status code and any error output, in a (Status,Secs,Errors) tuple.
#  Normal output from the build and execution stages is ignored. The cleanup
#  command is always run, even if earlier commands fail, but its status
#  and errors are always ignored in this case.

def InternalTime (Output) :

   #  (2026) The time a test program reports for its own repeat loop, as
   #  "Internal time <secs> s", or None if it does not report one.

   for Line in Output.split("\n") :
      if (Line.startswith("Internal time")) :
         try :
            return float(Line.split()[2])
         except (IndexError,ValueError) :
            return None
   return None

def BuildAndTimeProgram (
      BuildCommand1,BuildCommand2,ExecCommand,Nrpt,Nx,Ny,CleanupCommand) :

   Status = None
   Secs = 0.0
   InternalSecs = None
   
   #  We need at least two repeats, or we can't subtract off the overheads
   #  associated with starting the test and checking the results.
   
   if (Nrpt < 2) : Nrpt = 2

   #  We run through the varius stages of the process, the build stage(s)
   #  and then the execution of the test program. If there is a failure, we
   #  stop there, and Errors and Status will be as returned by the failing
   #  stage.
   
   #  Run the two build commands, if these are needed.
   
   if (BuildCommand1 != "") :
      (Status,Output,Errors) = ExecuteCommand(BuildCommand1)
      if (Status == None) :
         if (BuildCommand2 != "") :
            (Status,Output,Errors) = ExecuteCommand(BuildCommand2)
   if (Status == None) :
   
      #  No problems with the build, if any. Run the command that runs the
      #  test program, forming the command to be executed from the supplied
      #  command and the three parameters, Nrpt,Nx,Ny. Get the time at start
      #  and end and compute the elapsed time.
      
      Command = "%s %d %d %d" % (ExecCommand,Nrpt,Nx,Ny)

      #  (2026) Timed with a monotonic clock, and a run counts as failed if
      #  the program reports an error in its own result check: every test
      #  program prints "Error" and still exits with status 0. Before 2026
      #  only the exit status was checked, and the one-repeat run below
      #  overwrote the status of the timed run.

      Start = time.perf_counter()
      (Status,Output,Errors) = ExecuteCommand(Command)
      Secs = time.perf_counter() - Start
      if (Status == None and "Error" in Output) :
         Status = "Result check failed in '" + Command + "'"
         Errors = Output
      InternalSecs = InternalTime(Output)

   if (Status == None) :

      #  One wrinkle. If Nrpt is very low, say less than 10, it suggests the
      #  code being tested is quite slow, and this means the time to setup and
      #  check the results may be a significant fraction of the measured time.
      #  In this case, do one run with Nrpt set to 1, and allow for the time
      #  this takes to adjust the measured value of Secs. In fact, we might
      #  as well do this for all cases - the faster PDL tests, for example,
      #  still have very slow checking code.

      Command = "%s %d %d %d" % (ExecCommand,1,Nx,Ny)
      Start = time.perf_counter()
      (Status,Output,Errors) = ExecuteCommand(Command)
      Elapsed = time.perf_counter() - Start
      if (Status == None and "Error" in Output) :
         Status = "Result check failed in '" + Command + "'"
         Errors = Output

      #  (2026) A program that times its own repeat loop and prints
      #  "Internal time <secs> s" is timed by that instead of the wall clock.
      #  Only the MATLAB tests do this: MATLAB's start-up varies by several
      #  seconds from one launch to the next, which the wall-clock
      #  subtraction below cannot remove.

      if (InternalSecs != None and InternalTime(Output) != None) :
         Secs = InternalSecs
         Elapsed = InternalTime(Output)
      Secs = (Secs - Elapsed) * float(Nrpt) / float(Nrpt - 1)

   #  If a cleanup command is supplied, we run it no matter what, but only
   #  report its errors if everything else has gone fine so far.

   if (CleanupCommand != "") :
      (CleanStatus,Output,CleanErrors) = ExecuteCommand(CleanupCommand)
      if (Status == None) :
         Status = CleanStatus
         Errors = CleanErrors

   return (Status,Secs,Errors)

# ------------------------------------------------------------------------------

#                        L i s t  V e r s i o n
#
#  This lists the version of a compiler or language, given a command string
#  that can be used to get the version number, eg "c++ --version" which works
#  for both clang and gcc. This is also passed the name of the compiler/
#  language, and puts out one line to the terminal with the version number.

def ListVersion (Lang,Command) :

   (Status,Output,Errors) = ExecuteCommand(Command)

   #  For every example we work with in this program, the version number will
   #  be in the first line of what is returned, but some put write this to
   #  standard output and some to standard error. We try to see what we've got.

   if (Status) :
      print ("Unable to get version for",Lang,":",Status);
   else :
      OutputLines = Output.split("\n")
      ErrorLines = Errors.split("\n")
      if (len(OutputLines) > 0) :
         if (OutputLines[0] != "") :
            print (Lang,":",OutputLines[0])
      if (len(ErrorLines) > 0) :
         if (ErrorLines[0] != "") :
            print (Lang,":",ErrorLines[0])

# ------------------------------------------------------------------------------

#                        T e s t  D e s c r i p t i o n s
#
#  Each test is specified by a list containing the following items:
#  o A description of the language and any particular coding technique used.
#  o A description of the compiler and any compilation options used.
#  o A command used to build the test executable, or a null string.
#  o Any second command needed to build the test executable, or a null string.
#  o The command (without parameters) used to run the test.
#  o The number of repetitions to run - chosen to run for at least some seconds.
#  o A command used to clean up after the test, or a null string.
#
#  Adding a new test is a simple as creating a new list that defines it, and
#  then adding its name to the list of tests held in FullTests.
#
#  Note: Neither of the descriptions should contain commas, as they are written
#  out using a CSV (comma separated variable) format, and having commas in the
#  items confuses things. Note that the number of repetitions must be more than
#  one.

RawCclang = [
   "C : raw",
   "clang",
   "c++ -c csub.cpp -o csub.o",
   "c++ -o cmain cmain.cpp csub.o",
   "./cmain",
   100000,
   "rm -f cmain csub.o"]

RawCclangO = [
   "C : raw",
   "clang -O",
   "c++ -c -O csub.cpp -o csub.o",
   "c++ -o cmain -O cmain.cpp csub.o",
   "./cmain",
   1000000,
   "rm -f cmain csub.o"]

RawCclangO1 = [
   "C : raw",
   "clang -O1",
   "c++ -c -O1 csub.cpp -o csub.o",
   "c++ -o cmain -O1 cmain.cpp csub.o",
   "./cmain",
   1000000,
   "rm -f cmain csub.o"]

RawCclangO2 = [
   "C : raw",
   "clang -O2",
   "c++ -c -O2 csub.cpp -o csub.o",
   "c++ -o cmain -O2 cmain.cpp csub.o",
   "./cmain",
   2500000,
   "rm -f cmain csub.o"]

RawCclangO3 = [
   "C : raw",
   "clang -O3",
   "c++ -c -O3 csub.cpp -o csub.o",
   "c++ -o cmain -O3 cmain.cpp csub.o",
   "./cmain",
   2000000,
   "rm -f cmain csub.o"]

RawCclangO3native = [
   "C : raw",
   "clang -O3 native",
   "c++ -c -O3 -march=native csub.cpp -o csub.o",
   "c++ -o cmain -O3 -march=native cmain.cpp csub.o",
   "./cmain",
   5000000,
   "rm -f cmain csub.o"]

RawCgcc = [
   "C : raw",
   "g++",
   "g++ -c csub.cpp -o csub.o",
   "g++ -o cmain cmain.cpp csub.o",
   "./cmain",
   100000,
   "rm -f cmain csub.o"]

RawCgccO = [
   "C : raw",
   "g++ -O",
   "g++ -c -O csub.cpp -o csub.o",
   "g++ -o cmain -O cmain.cpp csub.o",
   "./cmain",
   1000000,
   "rm -f cmain csub.o"]

RawCgccO1 = [
   "C : raw",
   "g++ -O1",
   "g++ -c -O1 csub.cpp -o csub.o",
   "g++ -o cmain -O1 cmain.cpp csub.o",
   "./cmain",
   1000000,
   "rm -f cmain csub.o"]

RawCgccO2 = [
   "C : raw",
   "g++ -O2",
   "g++ -c -O2 csub.cpp -o csub.o",
   "g++ -o cmain -O2 cmain.cpp csub.o",
   "./cmain",
   2800000,
   "rm -f cmain csub.o"]

RawCgccO3 = [
   "C : raw",
   "g++ -O3",
   "g++ -c -O3 csub.cpp -o csub.o",
   "g++ -o cmain -O3 cmain.cpp csub.o",
   "./cmain",
   2700000,
   "rm -f cmain csub.o"]

RawCgccO3native = [
   "C : raw",
   "g++ -O3 native",
   "g++ -c -O3 -march=native csub.cpp -o csub.o",
   "g++ -o cmain -O3 -march=native cmain.cpp csub.o",
   "./cmain",
   5000000,
   "rm -f cmain csub.o"]

BoostCclang = [
   "C++ : Boost",
   "clang",
   "c++ -c cbsub.cpp -o cbsub.o",
   "c++ -o cbmain cbmain.cpp cbsub.o",
   "./cbmain",
   5000,
   "rm -f cbmain cbsub.o"]

BoostCclangO = [
   "C++ : Boost",
   "clang -O",
   "c++ -c -O cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O cbmain.cpp cbsub.o",
   "./cbmain",
   230000,
   "rm -f cbmain cbsub.o"]

BoostCclangO1 = [
   "C++ : Boost",
   "clang -O1",
   "c++ -c -O1 cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O1 cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCclangO2 = [
   "C++ : Boost",
   "clang -O2",
   "c++ -c -O2 cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O2 cbmain.cpp cbsub.o",
   "./cbmain",
   220000,
   "rm -f cbmain cbsub.o"]

BoostCclangO3 = [
   "C++ : Boost",
   "clang -O3",
   "c++ -c -O3 cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O3 cbmain.cpp cbsub.o",
   "./cbmain",
   290000,
   "rm -f cbmain cbsub.o"]

BoostCclangO3native = [
   "C++ : Boost",
   "clang -O3 native",
   "c++ -c -O3 -march=native cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O3 -march=native cbmain.cpp cbsub.o",
   "./cbmain",
   320000,
   "rm -f cbmain cbsub.o"]

BoostCgcc = [
   "C++ : Boost",
   "g++",
   "g++ -c cbsub.cpp -o cbsub.o",
   "g++ -o cbmain cbmain.cpp cbsub.o",
   "./cbmain",
   5000,
   "rm -f cbmain cbsub.o"]

BoostCgccO = [
   "C++ : Boost",
   "g++ -O",
   "g++ -c -O cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O cbmain.cpp cbsub.o",
   "./cbmain",
   250000,
   "rm -f cbmain cbsub.o"]

BoostCgccO1 = [
   "C++ : Boost",
   "g++ -O1",
   "g++ -c -O1 cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O1 cbmain.cpp cbsub.o",
   "./cbmain",
   70000,
   "rm -f cbmain cbsub.o"]

BoostCgccO2 = [
   "C++ : Boost",
   "g++ -O2",
   "g++ -c -O2 cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O2 cbmain.cpp cbsub.o",
   "./cbmain",
   240000,
   "rm -f cbmain cbsub.o"]

BoostCgccO3 = [
   "C++ : Boost",
   "g++ -O3",
   "g++ -c -O3 cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O3 cbmain.cpp cbsub.o",
   "./cbmain",
   340000,
   "rm -f cbmain cbsub.o"]

BoostCgccO3native = [
   "C++ : Boost",
   "g++ -O3 native",
   "g++ -c -O3 -march=native cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O3 -march=native cbmain.cpp cbsub.o",
   "./cbmain",
   330000,
   "rm -f cbmain cbsub.o"]

BoostCclangNoAssert = [
   "C++ : Boost no assert",
   "clang",
   "c++ -c -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   5000,
   "rm -f cbmain cbsub.o"]

BoostCclangONoAssert = [
   "C++ : Boost no assert",
   "clang -O",
   "c++ -c -O -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   520000,
   "rm -f cbmain cbsub.o"]

BoostCclangO1NoAssert = [
   "C++ : Boost no assert",
   "clang -O1",
   "c++ -c -O1 -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O1 -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   85000,
   "rm -f cbmain cbsub.o"]

BoostCclangO2NoAssert = [
   "C++ : Boost no assert",
   "clang -O2",
   "c++ -c -O2 -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O2 -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   770000,
   "rm -f cbmain cbsub.o"]

BoostCclangO3NoAssert = [
   "C++ : Boost no assert",
   "clang -O3",
   "c++ -c -O3 -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O3 -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   740000,
   "rm -f cbmain cbsub.o"]

BoostCclangO3nativeNoAssert = [
   "C++ : Boost no assert",
   "clang -O3 native",
   "c++ -c -O3 -march=native -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O3 -march=native -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   1050000,
   "rm -f cbmain cbsub.o"]

BoostCgccNoAssert = [
   "C++ : Boost no assert",
   "g++",
   "g++ -c -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   5000,
   "rm -f cbmain cbsub.o"]

BoostCgccONoAssert = [
   "C++ : Boost no assert",
   "g++ -O",
   "g++ -c -O -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   370000,
   "rm -f cbmain cbsub.o"]

BoostCgccO1NoAssert = [
   "C++ : Boost no assert",
   "g++ -O1",
   "g++ -c -O1 -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O1 -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   625000,
   "rm -f cbmain cbsub.o"]

BoostCgccO2NoAssert = [
   "C++ : Boost no assert",
   "g++ -O2",
   "g++ -c -O2 -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O2 -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   1000000,
   "rm -f cbmain cbsub.o"]

BoostCgccO3NoAssert = [
   "C++ : Boost no assert",
   "g++ -O3",
   "g++ -c -O3 -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O3 -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   1000000,
   "rm -f cbmain cbsub.o"]

BoostCgccO3nativeNoAssert = [
   "C++ : Boost no assert",
   "g++ -O3 native",
   "g++ -c -O3 -march=native -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O3 -march=native -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   1050000,
   "rm -f cbmain cbsub.o"]

CNumRclang = [
   "C : Num. rec.",
   "clang",
   "c++ -c cnrsub.cpp -o cnrsub.o",
   "c++ -o cnrmain cnrmain.cpp cnrsub.o",
   "./cnrmain",
   100000,
   "rm -f cnrmain cnrsub.o"]

CNumRclangO = [
   "C : Num. rec.",
   "clang -O",
   "c++ -c -O cnrsub.cpp -o cnrsub.o",
   "c++ -o cnrmain -O cnrmain.cpp cnrsub.o",
   "./cnrmain",
   1000000,
   "rm -f cnrmain cnrsub.o"]

CNumRclangO1 = [
   "C : Num. rec.",
   "clang -O1",
   "c++ -c -O1 cnrsub.cpp -o cnrsub.o",
   "c++ -o cnrmain -O1 cnrmain.cpp cnrsub.o",
   "./cnrmain",
   1000000,
   "rm -f cnrmain cnrsub.o"]

CNumRclangO2 = [
   "C : Num. rec.",
   "clang -O2",
   "c++ -c -O2 cnrsub.cpp -o cnrsub.o",
   "c++ -o cnrmain -O2 cnrmain.cpp cnrsub.o",
   "./cnrmain",
   2500000,
   "rm -f cnrmain cnrsub.o"]

CNumRclangO3 = [
   "C : Num. rec.",
   "clang -O3",
   "c++ -c -O3 cnrsub.cpp -o cnrsub.o",
   "c++ -o cnrmain -O3 cnrmain.cpp cnrsub.o",
   "./cnrmain",
   2500000,
   "rm -f cnrmain cnrsub.o"]

CNumRclangO3native = [
   "C : Num. rec.",
   "clang -O3 native",
   "c++ -c -O3 -march=native cnrsub.cpp -o cnrsub.o",
   "c++ -o cnrmain -O3 -march=native cnrmain.cpp cnrsub.o",
   "./cnrmain",
   5000000,
   "rm -f cnrmain cnrsub.o"]

CNumRgcc = [
   "C : Num. rec.",
   "g++",
   "g++ -c cnrsub.cpp -o cnrsub.o",
   "g++ -o cnrmain cnrmain.cpp cnrsub.o",
   "./cnrmain",
   100000,
   "rm -f cnrmain cnrsub.o"]

CNumRgccO = [
   "C : Num. rec.",
   "g++ -O",
   "g++ -c -O cnrsub.cpp -o cnrsub.o",
   "g++ -o cnrmain -O cnrmain.cpp cnrsub.o",
   "./cnrmain",
   500000,
   "rm -f cnrmain cnrsub.o"]

CNumRgccO1 = [
   "C : Num. rec.",
   "g++ -O1",
   "g++ -c -O1 cnrsub.cpp -o cnrsub.o",
   "g++ -o cnrmain -O1 cnrmain.cpp cnrsub.o",
   "./cnrmain",
   500000,
   "rm -f cnrmain cnrsub.o"]

CNumRgccO2 = [
   "C : Num. rec.",
   "g++ -O2",
   "g++ -c -O2 cnrsub.cpp -o cnrsub.o",
   "g++ -o cnrmain -O2 cnrmain.cpp cnrsub.o",
   "./cnrmain",
   2700000,
   "rm -f cnrmain cnrsub.o"]

CNumRgccO3 = [
   "C : Num. rec.",
   "g++ -O3",
   "g++ -c -O3 cnrsub.cpp -o cnrsub.o",
   "g++ -o cnrmain -O3 cnrmain.cpp cnrsub.o",
   "./cnrmain",
   2800000,
   "rm -f cnrmain cnrsub.o"]

CNumRgccO3native = [
   "C : Num. rec.",
   "g++ -O3 native",
   "g++ -c -O3 -march=native cnrsub.cpp -o cnrsub.o",
   "g++ -o cnrmain -O3 -march=native cnrmain.cpp cnrsub.o",
   "./cnrmain",
   5000000,
   "rm -f cnrmain cnrsub.o"]

VecCclang = [
   "C : vectors",
   "clang",
   "c++ -c cvsub.cpp -o cvsub.o",
   "c++ -o cvmain cvmain.cpp cvsub.o",
   "./cvmain",
   100000,
   "rm -f cvmain cvsub.o"]

VecCclangO = [
   "C : vectors",
   "clang -O",
   "c++ -c -O cvsub.cpp -o cvsub.o",
   "c++ -o cvmain -O cvmain.cpp cvsub.o",
   "./cvmain",
   1000000,
   "rm -f cvmain cvsub.o"]

VecCclangO1 = [
   "C : vectors",
   "clang -O1",
   "c++ -c -O1 cvsub.cpp -o cvsub.o",
   "c++ -o cvmain -O1 cvmain.cpp cvsub.o",
   "./cvmain",
   1000000,
   "rm -f cvmain cvsub.o"]

VecCclangO2 = [
   "C : vectors",
   "clang -O2",
   "c++ -c -O2 cvsub.cpp -o cvsub.o",
   "c++ -o cvmain -O2 cvmain.cpp cvsub.o",
   "./cvmain",
   2400000,
   "rm -f cvmain cvsub.o"]

VecCclangO3 = [
   "C : vectors",
   "clang -O3",
   "c++ -c -O3 cvsub.cpp -o cvsub.o",
   "c++ -o cvmain -O3 cvmain.cpp cvsub.o",
   "./cvmain",
   2400000,
   "rm -f cvmain cvsub.o"]

VecCclangO3native = [
   "C : vectors",
   "clang -O3 native",
   "c++ -c -O3 -march=native cvsub.cpp -o cvsub.o",
   "c++ -o cvmain -O3 -march=native cvmain.cpp cvsub.o",
   "./cvmain",
   5000000,
   "rm -f cvmain cvsub.o"]

VecCgcc = [
   "C : vectors",
   "g++",
   "g++ -c cvsub.cpp -o cvsub.o",
   "g++ -o cvmain cvmain.cpp cvsub.o",
   "./cvmain",
   100000,
   "rm -f cvmain cvsub.o"]

VecCgccO = [
   "C : vectors",
   "g++ -O",
   "g++ -c -O cvsub.cpp -o cvsub.o",
   "g++ -o cvmain -O cvmain.cpp cvsub.o",
   "./cvmain",
   1000000,
   "rm -f cvmain cvsub.o"]

VecCgccO1 = [
   "C : vectors",
   "g++ -O1",
   "g++ -c -O1 cvsub.cpp -o cvsub.o",
   "g++ -o cvmain -O1 cvmain.cpp cvsub.o",
   "./cvmain",
   1000000,
   "rm -f cvmain cvsub.o"]

VecCgccO2 = [
   "C : vectors",
   "g++ -O2",
   "g++ -c -O2 cvsub.cpp -o cvsub.o",
   "g++ -o cvmain -O2 cvmain.cpp cvsub.o",
   "./cvmain",
   2600000,
   "rm -f cvmain cvsub.o"]

VecCgccO3 = [
   "C : vectors",
   "g++ -O3",
   "g++ -c -O3 cvsub.cpp -o cvsub.o",
   "g++ -o cvmain -O3 cvmain.cpp cvsub.o",
   "./cvmain",
   2600000,
   "rm -f cvmain cvsub.o"]

VecCgccO3native = [
   "C : vectors",
   "g++ -O3 native",
   "g++ -c -O3 -march=native cvsub.cpp -o cvsub.o",
   "g++ -o cvmain -O3 -march=native cvmain.cpp cvsub.o",
   "./cvmain",
   5000000,
   "rm -f cvmain cvsub.o"]

Fortran = [
   "Fortran",
   "gfortran",
   "gfortran -c -o cfsub.o cfsub.f",
   "gfortran -o cfmain cfmain.f cfsub.o",
   "./cfmain",
   160000,
   "rm -f cfmain cfsub.o"]

FortranO = [
   "Fortran",
   "gfortran -O",
   "gfortran -c -o cfsub.o -O cfsub.f",
   "gfortran -o cfmain -O cfmain.f cfsub.o",
   "./cfmain",
   500000,
   "rm -f cfmain cfsub.o"]

FortranO1 = [
   "Fortran",
   "gfortran -O1",
   "gfortran -c -o cfsub.o -O1 cfsub.f",
   "gfortran -o cfmain -O1 cfmain.f cfsub.o",
   "./cfmain",
   500000,
   "rm -f cfmain cfsub.o"]

FortranO2 = [
   "Fortran",
   "gfortran -O2",
   "gfortran -c -o cfsub.o -O2 cfsub.f",
   "gfortran -o cfmain -O2 cfmain.f cfsub.o",
   "./cfmain",
   1500000,
   "rm -f cfmain cfsub.o"]

FortranO3 = [
   "Fortran",
   "gfortran -O3",
   "gfortran -c -o cfsub.o -O3 cfsub.f",
   "gfortran -o cfmain -O3 cfmain.f cfsub.o",
   "./cfmain",
   1500000,
   "rm -f cfmain cfsub.o"]

FortranO3native = [
   "Fortran",
   "gfortran -O3 native",
   "gfortran -c -o cfsub.o -O3 -march=native cfsub.f",
   "gfortran -o cfmain -O3 -march=native cfmain.f cfsub.o",
   "./cfmain",
   5000000,
   "rm -f cfmain cfsub.o"]

Assembler = [
   "Assembler",
   "clang (arm64)",
   "c++ -c -o cnrsub_arm.o cnrsub_arm.s",
   "c++ -o assmain -O cnrmain.cpp cnrsub_arm.o",
   "./assmain",
   5000000,
   "rm -f assmain cnrsub_arm.o"]

Java = [
   "Java",
   "Java",
   "javac -g:none csub.java",
   "",
   "java csub",
   500000,
   "rm -f csub.class"]

Tcl = [
   "Tcl : raw",
   "tclsh",
   "",
   "",
   "tclsh ctest.tcl",
   200,
   ""]

Julia = [
   "Julia",
   "julia",
   "",
   "",
   "julia csub.jl",
   1500000,
   ""]

JuliaO0 = [
   "Julia",
   "julia -O0",
   "",
   "",
   "julia -O0 csub.jl",
   50000,
   ""]

JuliaO1 = [
   "Julia",
   "julia -O1",
   "",
   "",
   "julia -O1 csub.jl",
   200000,
   ""]

JuliaO2 = [
   "Julia",
   "julia -O2",
   "",
   "",
   "julia -O2 csub.jl",
   1500000,
   ""]

JuliaO3 = [
   "Julia",
   "julia -O3",
   "",
   "",
   "julia -O3 csub.jl",
   1500000,
   ""]

JuliaInt32 = [
   "Julia",
   "julia (int32)",
   "",
   "",
   "julia -O3 csubint32nb.jl",
   5000000,
   ""]

RawR = [
   "R : raw",
   "Rscript",
   "",
   "",
   "Rscript csub.r",
   5000,
   ""]

Rref = [
   "R : ref class",
   "Rscript",
   "",
   "",
   "Rscript csubref.r",
   7,
   ""]

Router = [
   "R : outer",
   "Rscript",
   "",
   "",
   "Rscript csubouter.r",
   20000,
   ""]

Perl = [
   "Perl",
   "Perl",
   "",
   "",
   "perl csubraw.pl",
   5000,
   ""]

#  PDL "raw" per-element access.  csubpdl.pl now uses ->at and ->set
#  (the proper per-element primitives) rather than the ->slice form
#  used in 2019.  See the comment block at the top of csubpdl.pl for
#  the history.  ->at/->set is roughly 12x faster than ->slice; rep
#  count is bumped from 10 to 1000 accordingly.
PerlPDLraw = [
   "Perl/PDL : raw",
   "Perl/PDL",
   "",
   "",
   "perl csubpdl.pl",
   1000,
   ""]

PerlPDLvec = [
   "Perl/PDL : vectors",
   "Perl/PDL",
   "",
   "",
   "perl csubpdlvec.pl",
   50000,
   ""]

PerlPDLary = [
   "Perl/PDL : arrays",
   "Perl/PDL",
   "",
   "",
   "perl csubpdlary.pl",
   140000,
   ""]

#  Perl/PDL using Inline::Pdlpp — compiles a small C kernel via PDL::PP the
#  first time it runs and caches it under ./_Inline.  We warm the cache with
#  a single-rep call (Build1) so the timed run measures execution only, not
#  the one-off compile.
PerlPDLpp = [
   "Perl/PDL : pp",
   "Perl/PDL",
   "perl csubpdlpp.pl 1 2000 10",
   "",
   "perl csubpdlpp.pl",
   1000000,
   ""]

Python2 = [
   "Python : lists",
   "Python2",
   "",
   "",
   "python csubraw.py",
   3000,
   ""]

Python2np = [
   "Python : numpy raw",
   "Python2",
   "",
   "",
   "python csubnp.py",
   600,
   ""]

Python2vec = [
   "Python : vectors",
   "Python2",
   "",
   "",
   "python csubnpv.py",
   110000,
   ""]

Python2ary = [
   "Python : arrays",
   "Python2",
   "",
   "",
   "python csubnpna.py",
   90000,
   ""]

Python3 = [
   "Python : lists",
   "Python3",
   "",
   "",
   "python3 csubraw.py",
   9000,
   ""]

Python3np = [
   "Python : numpy raw",
   "Python3",
   "",
   "",
   "python3 csubnp.py",
   1500,
   ""]

Python3vec = [
   "Python : vectors",
   "Python3",
   "",
   "",
   "python3 csubnpv.py",
   200000,
   ""]

Python3ary = [
   "Python : arrays",
   "Python3",
   "",
   "",
   "python3 csubnpna.py",
   180000,
   ""]

Python3npNumba = [
   "Python : numpy raw",
   "Python3 numba",
   "",
   "",
   "python3 csubnp-numba.py",
   1400000,
   ""]

Rust = [
   "Rust",
   "Rustc",
   "rustc crsmain.rs ",
   "",
   "./crsmain",
   8000,
   "rm -f crsmain"]

RustO = [
   "Rust",
   "Rustc -O",
   "rustc -O crsmain.rs ",
   "",
   "./crsmain",
   300000,
   "rm -f crsmain"]

RustO3 = [
   "Rust",
   "Rustc -O3",
   "rustc -C opt-level=3 crsmain.rs ",
   "",
   "./crsmain",
   300000,
   "rm -f crsmain"]

RustO3native = [
   "Rust",
   "Rustc -O3 native",
   "rustc -C target-cpu=native -C opt-level=3 crsmain.rs ",
   "",
   "./crsmain",
   300000,
   "rm -f crsmain"]

RustO3nativeIter = [
   "Rust",
   "Rustc iterators",
   "rustc -C target-cpu=native -C opt-level=3 crsmain_iter.rs ",
   "",
   "./crsmain_iter",
   500000,
   "rm -f crsmain_iter"]

RustO3nativeUnsafe = [
   "Rust",
   "Rustc unsafe",
   "rustc -C target-cpu=native -C opt-level=3 crsmain_unsafe.rs ",
   "",
   "./crsmain_unsafe",
   450000,
   "rm -f crsmain_unsafe"]

Javascript = [
   "Javascript",
   "Node.js",
   "",
   "",
   "node cjstest.js",
   100000,
   ""]

JavascriptNoopt = [
   "Javascript",
   "Node.js --no-opt",
   "",
   "",
   "node --no-opt cjstest.js",
   125000,
   ""]

JavascriptBun = [
   "Javascript",
   "Bun",
   "",
   "",
   "bun cjstest.js",
   1000000,
   ""]

JavascriptDeno = [
   "Javascript",
   "Deno",
   "",
   "",
   "deno run cjstest.js",
   500000,
   ""]

RubyRaw26 = [
   "Ruby : raw",
   "ruby 2.6",                               # macOS-shipped Ruby
   "",
   "",
   "/usr/bin/ruby csubraw.rb",
   5000,
   ""]

RubyRaw33 = [
   "Ruby : raw",
   "ruby 3.3",
   "",
   "",
   "ruby csubraw.rb",
   5000,
   ""]

RubyRaw33YJIT = [
   "Ruby : raw",
   "ruby 3.3 +YJIT",
   "",
   "",
   "ruby --yjit csubraw.rb",
   10000,
   ""]

RubyNumo = [
   "Ruby : Numo",
   "ruby 3.3",
   "",
   "",
   "ruby csubnumo.rb",
   150000,
   ""]

RubyNumoYJIT = [
   "Ruby : Numo",
   "ruby 3.3 +YJIT",
   "",
   "",
   "ruby --yjit csubnumo.rb",
   150000,
   ""]

#  Go.  Build to a temporary binary, run, clean up.  Default build flags
#  (no -O switch in Go's tradition; the SSA backend is always optimising).
Go = [
   "Go",
   "go",
   "go build -o csub_go csubraw.go",
   "",
   "./csub_go",
   1000000,
   "rm -f csub_go"]

#  Go without bounds-check elision disabled — shows what BCE costs.
GoNoBCE = [
   "Go",
   "go -B (no BCE)",
   "go build -gcflags=-B -o csub_go csubraw.go",
   "",
   "./csub_go",
   1000000,
   "rm -f csub_go"]

#  LuaJIT — tracing JIT for Lua, famously fast on tight numeric loops.
LuaJIT = [
   "Lua",
   "LuaJIT",
   "",
   "",
   "luajit csubraw.lua",
   1000000,
   ""]

#  C# / .NET 8.  Build via `dotnet build -c Release` then run the apphost.
#  DOTNET_ROOT is set in the bootstrap above so the apphost can find the
#  runtime.
CSharp = [
   "C#",
   ".NET 8",
   "dotnet build cs_proj -c Release -o /tmp/csbin --nologo -v q",
   "",
   "/tmp/csbin/cs_proj",
   1000000,
   "rm -rf /tmp/csbin"]

#  Crystal — Ruby-syntax statically typed AOT-compiled language.  Use
#  --release for full LLVM optimisation; without it Crystal is roughly
#  3-5× slower.
Crystal = [
   "Crystal",
   "crystal --release",
   "crystal build --release -o csub_cr csubraw.cr",
   "",
   "./csub_cr",
   1000000,
   "rm -f csub_cr"]

#  OCaml — ocamlopt's native compiler.  -unsafe disables bounds checks
#  on Array.get/set (Array.unsafe_get always omits them; -unsafe makes
#  the safe variants do the same).
OCaml = [
   "OCaml",
   "ocamlopt -O3",
   "ocamlopt -O3 -unsafe csubraw.ml -o csub_ml",
   "",
   "./csub_ml",
   1000000,
   "rm -f csub_ml csubraw.cmi csubraw.cmx csubraw.o"]

#  PyPy — same csubraw.py the CPython tests use, but executed by the
#  PyPy interpreter, which has a tracing JIT.  No code change required.
PyPy = [
   "Python : lists",
   "PyPy3",
   "",
   "",
   #  `pypy3` here is the shim in ../bin/ — see run-benchmarks.sh.
   #  We can't put tools/pypy/bin on PATH because PyPy ships its own
   #  python/python3 symlinks that would hijack every CPython test.
   "pypy3 csubraw.py",
   500000,
   ""]

#  Zig — modern systems language, AOT via LLVM (same backend as clang).
#  -O ReleaseFast enables full optimisation and disables runtime safety
#  checks for the closest fair comparison with `clang -O3 native`.
Zig = [
   "Zig",
   "zig -O ReleaseFast",
   "zig build-exe -O ReleaseFast csubraw.zig -femit-bin=csub_zig",
   "",
   "./csub_zig",
   1000000,
   "rm -f csub_zig csubraw.o"]

#  SBCL Common Lisp — untyped variant.  Generic arithmetic, dispatched
#  array access; the slow tier.
SBCLUntyped = [
   "Lisp",
   "SBCL untyped",
   "",
   "",
   "sbcl --script csubraw.lisp",
   20000,
   ""]

#  SBCL Common Lisp — typed variant with full (declare (type ...))
#  declarations.  SBCL's compiler emits tight machine code; should
#  land in the C-class tier.
SBCLTyped = [
   "Lisp",
   "SBCL typed",
   "",
   "",
   "sbcl --script csubraw-typed.lisp",
   1000000,
   ""]

#  Haskell GHC — purely functional language, lazy by default but with
#  strict (BangPatterns) annotations on the hot variables and unboxed
#  doubles via IOUArray, the inner loop compiles to tight native code.
Haskell = [
   "Haskell",
   "GHC -O2",
   "ghc -O2 -funbox-strict-fields csubraw.hs -o csub_hs",
   "",
   "./csub_hs",
   1000000,
   "rm -f csub_hs csubraw.o csubraw.hi"]

#  F# -- same .NET 8 runtime as the C# entry, very different language.
FSharp = [
   "F#",
   ".NET 8",
   "dotnet build fs_proj -c Release -o /tmp/fsbin --nologo -v q",
   "",
   "/tmp/fsbin/fs_proj",
   1000000,
   "rm -rf /tmp/fsbin"]

#  C# AOT -- PublishAot=true compiles directly to native via the
#  ILCompiler.  Compare against the JIT result in CSharp above.
CSharpAOT = [
   "C#",
   ".NET 8 AOT",
   "dotnet publish cs_aot_proj -c Release -r osx-arm64 -o /tmp/csaotbin --nologo -v q",
   "",
   "/tmp/csaotbin/cs_aot_proj",
   1000000,
   "rm -rf /tmp/csaotbin"]

#  D / LDC -- LLVM-based D compiler.  -release -boundscheck=off matches
#  the no-runtime-checks position of the optimised C tests.
DLang = [
   "D",
   "ldc2 -O3 -release",
   "ldc2 -O3 -release -boundscheck=off csubraw.d -of=csub_d",
   "",
   "./csub_d",
   1000000,
   "rm -f csub_d csubraw.o"]

#  Nim -- compiles to C, then through clang.  -d:danger turns off all
#  runtime safety checks; --gc:arc is the deterministic refcount GC.
Nim = [
   "Nim",
   "nim -d:danger",
   "nim c -d:danger --gc:arc -o:csub_nim csubraw.nim",
   "",
   "./csub_nim",
   1000000,
   "rm -rf csub_nim nimcache"]

#  Octave -- Matlab clone.  Two variants: element-wise loops and
#  vectorised broadcasting.  The loop version exercises Octave's
#  interpreter; the vectorised version exercises Octave's BLAS-style
#  inner kernel.
#  Octave -- system install via Homebrew.  Two variants: element-wise
#  loops (exercises Octave's interpreter; very slow) and vectorised
#  broadcasting (exercises Octave's BLAS-style fast path).
OctaveLoop = [
   "Octave",
   "octave loop",
   "",
   "",
   "octave-cli --no-gui --norc -q csubraw.m",
   100,
   ""]

OctaveVec = [
   "Octave",
   "octave vectorised",
   "",
   "",
   "octave-cli --no-gui --norc -q csubvec.m",
   60000,
   ""]

#  Kotlin -- JVM language.  `kotlinc` here resolves to the shim in
#  ../bin/ (see run-benchmarks.sh), which bypasses the broken conda
#  bin/kotlinc shell wrapper and exec's libexec/kotlin/bin/kotlinc.
KotlinJVM = [
   "Kotlin",
   "kotlinc + JVM",
   "kotlinc csubraw.kt -include-runtime -d /tmp/csub_kt.jar",
   "",
   "java -jar /tmp/csub_kt.jar",
   500000,
   "rm -f /tmp/csub_kt.jar"]

#  PyPy + numpy -- not the speedup people expect.  PyPy emulates the
#  CPython C API (cpyext) for compiled extensions, and numpy is one
#  of the largest such extensions.  The cpyext layer is much slower
#  than CPython's native fast path, so PyPy + numpy lands in the
#  *slowest* tier of the dataset, not a faster one.
PyPyNumpy = [
   "Python : numpy raw",
   "PyPy3",
   "",
   "",
   "pypy3 csubnp.py",   # pypy3 is the shim in ../bin/, see PyPy above
   200,
   ""]

#  J — the array language.  Whole kernel collapses to one outer-product
#  expression: out =. y + (i. ny) +/ i. nx
J = [
   "J",
   "jconsole",
   "",
   "",
   "jconsole csubraw.ijs",
   1000000,
   ""]

Swift = [
   "Swift",
   "Swiftc",
   "xcrun swiftc -o cstest cstest.swift",
   "",
   "./cstest",
   1000,
   "rm -f cstest"]

SwiftOnone = [
   "Swift",
   "Swiftc -Onone",
   "xcrun swiftc -o cstest -Onone cstest.swift",
   "",
   "./cstest",
   1000,
   "rm -f cstest"]

SwiftO = [
   "Swift",
   "Swiftc -O",
   "xcrun swiftc -o cstest -O cstest.swift",
   "",
   "./cstest",
   300000,
   "rm -f cstest"]

SwiftOunchecked = [
   "Swift",
   "Swiftc -Ounchecked",
   "xcrun swiftc -o cstest -Ounchecked cstest.swift",
   "",
   "./cstest",
   500000,
   "rm -f cstest"]

#  FullTests is simply a list of all the structures that define tests to
#  be run. The order is not particularly important.

#  Compiled Python, 2026.  Four routes to native code for the same loops:
#  Codon compiles Keith's csubraw.py list version ahead of time to a native
#  executable (bin/codon-pybuild drops only its __future__ import); Cython
#  and Pythran compile the csubnp.py numpy subroutine to a CPython extension
#  module, driven by csubext.py, in the tools/pyext venv (bin/pyext-python);
#  Mojo is a port of csubraw.py to Mojo's typed lists.  Variant labels are
#  kept to 20 characters, the width of the harness's summary column.

CodonLists = [
   "Python : lists",
   "Codon",
   "codon-pybuild csubraw.py /tmp/csub_codon",
   "",
   "/tmp/csub_codon",
   300000,
   "rm -f /tmp/csub_codon"]

CythonUntyped = [
   "Python : numpy raw",
   "Cython untyped",
   "pyext-python -m Cython.Build.Cythonize -i -3 csubcy_untyped.pyx",
   "",
   "pyext-python csubext.py csubcy_untyped",
   2000,
   "rm -rf csubcy_untyped.c csubcy_untyped.cpython-*.so build"]

CythonTyped = [
   "Python : numpy raw",
   "Cython typed",
   "pyext-python -m Cython.Build.Cythonize -i -3 csubcy_typed.pyx",
   "",
   "pyext-python csubext.py csubcy_typed",
   1000000,
   "rm -rf csubcy_typed.c csubcy_typed.cpython-*.so build"]

CythonChecked = [
   "Python : numpy raw",
   "Cython typed+checks",
   "pyext-python -m Cython.Build.Cythonize -i -3 csubcy_checked.pyx",
   "",
   "pyext-python csubext.py csubcy_checked",
   500000,
   "rm -rf csubcy_checked.c csubcy_checked.cpython-*.so build"]

Pythran = [
   "Python : numpy raw",
   "Pythran",
   "pyext-python -m pythran.run -O3 csubpt.py",
   "",
   "pyext-python csubext.py csubpt",
   1000000,
   "rm -f csubpt.cpython-*.so"]

Mojo = [
   "Mojo",
   "mojo build",
   "mojo build csubraw.mojo -o /tmp/csub_mojo",
   "",
   "/tmp/csub_mojo",
   100000,
   "rm -f /tmp/csub_mojo"]

MojoNoAssert = [
   "Mojo",
   "mojo -D ASSERT=none",
   "mojo build -D ASSERT=none csubraw.mojo -o /tmp/csub_mojo",
   "",
   "/tmp/csub_mojo",
   300000,
   "rm -f /tmp/csub_mojo"]

#  Perl without PDL, 2026: the csub() kernel in C via Inline::C (compiled
#  and cached on first use, so Build1 is a one-repeat warm-up run, as for
#  PDL::PP).  csubinlav.pl keeps csubraw.pl's arrays of Perl scalars and
#  walks them through the Perl API; csubinlpk.pl uses packed doubles.

PerlInlineAV = [
   "Perl : Inline::C AV",
   "Perl",
   "perl csubinlav.pl 1 2000 10",
   "",
   "perl csubinlav.pl",
   50000,
   ""]

PerlInlinePacked = [
   "Perl : Inline::C packed",
   "Perl",
   "perl csubinlpk.pl 1 2000 10",
   "",
   "perl csubinlpk.pl",
   1000000,
   ""]

#  Raku (Rakudo on MoarVM), 2026.  Four idioms: Arrays of Arrays ("raw",
#  csubraw.raku), native num rows with native int counters (csubnat.raku),
#  one shaped native 2D array (csubshp.raku) and whole-row hyperoperators
#  (csubhyp.raku).  MVM_SPESH_DISABLE=1 switches off MoarVM's runtime
#  specialiser and its JIT, leaving the plain bytecode interpreter.

RakuRaw = [
   "Raku : raw",
   "rakudo",
   "",
   "",
   "raku csubraw.raku",
   300,
   ""]

RakuRawNoSpesh = [
   "Raku : raw",
   "rakudo no spesh",
   "",
   "",
   "env MVM_SPESH_DISABLE=1 raku csubraw.raku",
   60,
   ""]

RakuNative = [
   "Raku : native",
   "rakudo",
   "",
   "",
   "raku csubnat.raku",
   800,
   ""]

RakuNativeNoSpesh = [
   "Raku : native",
   "rakudo no spesh",
   "",
   "",
   "env MVM_SPESH_DISABLE=1 raku csubnat.raku",
   120,
   ""]

RakuShaped = [
   "Raku : shaped",
   "rakudo",
   "",
   "",
   "raku csubshp.raku",
   200,
   ""]

RakuHyper = [
   "Raku : hyper",
   "rakudo",
   "",
   "",
   "raku csubhyp.raku",
   800,
   ""]

#  More languages, 2026 (second batch).  MATLAB runs csubraw.m and
#  csubvec.m ported to functions (csubraw_ml.m, csubvec_ml.m) through
#  bin/matlab-run; its ~13 s startup is why its repeat counts are high.
#  GDL (the open-source IDL) runs csubraw_gdl.pro and csubvec_gdl.pro
#  through bin/gdl-run.  Clojure on persistent vectors and on Java double
#  arrays; Elixir on Erlang :array and as a map over lists; Chapel built
#  with and without --fast.

MatlabLoop = [
   "MATLAB",
   "matlab loop",
   "",
   "",
   "matlab-run csubraw_ml",
   1000000,
   ""]

MatlabVec = [
   "MATLAB",
   "matlab vectorised",
   "",
   "",
   "matlab-run csubvec_ml",
   2000000,
   ""]

GDLLoop = [
   "GDL",
   "gdl loop",
   "",
   "",
   "gdl-run csubraw_gdl",
   3000,
   ""]

GDLVec = [
   "GDL",
   "gdl vectorised",
   "",
   "",
   "gdl-run csubvec_gdl",
   1000000,
   ""]

ClojureVec = [
   "Clojure : vectors",
   "clojure",
   "",
   "",
   "clojure -M csubraw.clj",
   4000,
   ""]

ClojureArr = [
   "Clojure : arrays",
   "clojure",
   "",
   "",
   "clojure -M csubarr.clj",
   700000,
   ""]

ElixirArray = [
   "Elixir : array",
   "elixir",
   "",
   "",
   "elixir csubraw.exs",
   4000,
   ""]

ElixirMap = [
   "Elixir : map",
   "elixir",
   "",
   "",
   "elixir csubmap.exs",
   6000,
   ""]

ChapelFast = [
   "Chapel",
   "chpl --fast",
   "chpl --fast csubraw.chpl -o /tmp/csub_chpl",
   "",
   "/tmp/csub_chpl",
   1500000,
   "rm -f /tmp/csub_chpl"]

Chapel = [
   "Chapel",
   "chpl",
   "chpl csubraw.chpl -o /tmp/csub_chpl",
   "",
   "/tmp/csub_chpl",
   5000,
   "rm -f /tmp/csub_chpl"]

#  Runtime variants, 2026: the same source under another runtime.  Plain
#  PUC Lua beside LuaJIT; CPython 3.14 with its experimental JIT switched
#  on; GraalPy and TruffleRuby (GraalVM's Truffle JITs, via shims in bin/
#  because their own bin/ has python and ruby); and Keith's C kernel
#  (cmain.cpp + csub.cpp) compiled to WebAssembly with zig cc, with and
#  without 128-bit SIMD, run in wasmtime and in Node (wasirun.mjs).

LuaPUC = [
   "Lua",
   "lua 5.5",
   "",
   "",
   "lua csubraw.lua",
   20000,
   ""]

Python3JIT = [
   "Python : lists",
   "Python3 JIT",
   "",
   "",
   "env PYTHON_JIT=1 python3 csubraw.py",
   8000,
   ""]

Python3npJIT = [
   "Python : numpy raw",
   "Python3 JIT",
   "",
   "",
   "env PYTHON_JIT=1 python3 csubnp.py",
   1600,
   ""]

GraalPy = [
   "Python : lists",
   "GraalPy",
   "",
   "",
   "graalpy csubraw.py",
   40000,
   ""]

GraalPyNumpy = [
   "Python : numpy raw",
   "GraalPy",
   "",
   "",
   "graalpy csubnp.py",
   150,
   ""]

TruffleRuby = [
   "Ruby : raw",
   "TruffleRuby",
   "",
   "",
   "truffleruby csubraw.rb",
   400000,
   ""]

WasmWasmtime = [
   "C : raw",
   "wasm wasmtime",
   "zig cc -target wasm32-wasi -O3 -fno-exceptions -x c++ cmain.cpp csub.cpp -o /tmp/csub.wasm",
   "",
   "wasmtime /tmp/csub.wasm",
   600000,
   "rm -f /tmp/csub.wasm"]

WasmWasmtimeSimd = [
   "C : raw",
   "wasm simd wasmtime",
   "zig cc -target wasm32-wasi -O3 -msimd128 -fno-exceptions -x c++ cmain.cpp csub.cpp -o /tmp/csub.wasm",
   "",
   "wasmtime /tmp/csub.wasm",
   2000000,
   "rm -f /tmp/csub.wasm"]

WasmNode = [
   "C : raw",
   "wasm Node.js",
   "zig cc -target wasm32-wasi -O3 -fno-exceptions -x c++ cmain.cpp csub.cpp -o /tmp/csub.wasm",
   "",
   "node wasirun.mjs /tmp/csub.wasm",
   250000,
   "rm -f /tmp/csub.wasm"]

WasmNodeSimd = [
   "C : raw",
   "wasm simd Node.js",
   "zig cc -target wasm32-wasi -O3 -msimd128 -fno-exceptions -x c++ cmain.cpp csub.cpp -o /tmp/csub.wasm",
   "",
   "node wasirun.mjs /tmp/csub.wasm",
   400000,
   "rm -f /tmp/csub.wasm"]

#  APL (Dyalog 20.0), 2026: Keith's kernel as explicit :For loops
#  (csubraw.apls) and as the one-line array form in+(⍳ny)∘.+⍳nx
#  (csubary.apls), run with dyalogscript.

AplLoop = [
   "APL",
   "dyalog loop",
   "",
   "",
   "dyalogscript csubraw.apls",
   200,
   ""]

AplArray = [
   "APL",
   "dyalog array",
   "",
   "",
   "dyalogscript csubary.apls",
   700000,
   ""]

#  Third batch, 2026.  Swift with one flat array (cstestflat.swift: Keith's
#  cstest.swift with [Float] indexed Iy*Nx+Ix instead of arrays of rows);
#  Dart under its JIT and compiled ahead of time; PHP 8 without and with
#  its opcache JIT; Chez Scheme at the default and the unsafe optimize
#  level; awk (string-keyed 2D arrays) in mawk and gawk; bash (integer-only,
#  flat arrays); Ada with its default checks and with -gnatp.  GNAT comes
#  through bin/gnatmake, which keeps GNAT's own gcc/g++ off PATH.

SwiftFlatO = [
   "Swift : flat",
   "Swiftc -O",
   "xcrun swiftc -o /tmp/cstestflat -O cstestflat.swift",
   "",
   "/tmp/cstestflat",
   300000,
   "rm -f /tmp/cstestflat"]

SwiftFlatOunchecked = [
   "Swift : flat",
   "Swiftc -Ounchecked",
   "xcrun swiftc -o /tmp/cstestflat -Ounchecked cstestflat.swift",
   "",
   "/tmp/cstestflat",
   2000000,
   "rm -f /tmp/cstestflat"]

DartJIT = [
   "Dart",
   "dart run",
   "",
   "",
   "dart run csubraw.dart",
   500000,
   ""]

DartAOT = [
   "Dart",
   "dart compile exe",
   "dart compile exe csubraw.dart -o /tmp/csub_dart",
   "",
   "/tmp/csub_dart",
   300000,
   "rm -f /tmp/csub_dart"]

PHP = [
   "PHP",
   "php 8.5",
   "",
   "",
   "php csubraw.php",
   15000,
   ""]

PHPJIT = [
   "PHP",
   "php 8.5 JIT",
   "",
   "",
   "php -d opcache.enable_cli=1 -d opcache.jit=tracing -d opcache.jit_buffer_size=64M csubraw.php",
   70000,
   ""]

ChezScheme = [
   "Scheme",
   "chez",
   "",
   "",
   "chez --script csubraw.ss",
   150000,
   ""]

ChezSchemeO3 = [
   "Scheme",
   "chez opt-level 3",
   "",
   "",
   "chez --optimize-level 3 --script csubraw.ss",
   500000,
   ""]

Mawk = [
   "awk",
   "mawk",
   "",
   "",
   "mawk -f csubraw.awk",
   600,
   ""]

Gawk = [
   "awk",
   "gawk",
   "",
   "",
   "gawk -f csubraw.awk",
   900,
   ""]

Bash = [
   "bash",
   "bash 5.3",
   "",
   "",
   "/opt/homebrew/bin/bash csubraw.sh",
   40,
   ""]

AdaO3 = [
   "Ada",
   "gnatmake -O3",
   "gnatmake -q -f -O3 csubraw.adb -o /tmp/csub_ada -D /tmp",
   "",
   "/tmp/csub_ada",
   700000,
   "rm -f /tmp/csub_ada /tmp/csubraw.ali /tmp/csubraw.o"]

AdaO3gnatp = [
   "Ada",
   "gnatmake -O3 -gnatp",
   "gnatmake -q -f -O3 -gnatp csubraw.adb -o /tmp/csub_ada -D /tmp",
   "",
   "/tmp/csub_ada",
   900000,
   "rm -f /tmp/csub_ada /tmp/csubraw.ali /tmp/csubraw.o"]

#  Fourth batch, 2026: idiom and precision variants of existing languages.
#  Keith's C in double precision (csubd.cpp/cmaind.cpp, float -> double and
#  nothing else); Fortran array syntax and do concurrent (cfsubarr.f90,
#  cfsubdc.f90, drop-in replacements for cfsub.f linked with his cfmain.f);
#  Julia dot-broadcast (csubbcast.jl); JavaScript on flat Float64Arrays
#  (cjstestflat.js) in Node, Bun and Deno; Swift with a 2D Grid struct over
#  one flat array (cstestgrid.swift).

RawCdclangO3 = [
   "C : raw double",
   "clang -O3",
   "c++ -c -O3 csubd.cpp -o csubd.o",
   "c++ -o cmaind -O3 cmaind.cpp csubd.o",
   "./cmaind",
   1500000,
   "rm -f cmaind csubd.o"]

RawCdclangO3native = [
   "C : raw double",
   "clang -O3 native",
   "c++ -c -O3 -march=native csubd.cpp -o csubd.o",
   "c++ -o cmaind -O3 -march=native cmaind.cpp csubd.o",
   "./cmaind",
   1500000,
   "rm -f cmaind csubd.o"]

FortranArray = [
   "Fortran : array",
   "gfortran -O3 native",
   "gfortran -c -o cfsubarr.o -O3 -march=native cfsubarr.f90",
   "gfortran -o cfmain -O3 -march=native cfmain.f cfsubarr.o",
   "./cfmain",
   300000,
   "rm -f cfmain cfsubarr.o"]

FortranDoConc = [
   "Fortran : do concurrent",
   "gfortran -O3 native",
   "gfortran -c -o cfsubdc.o -O3 -march=native cfsubdc.f90",
   "gfortran -o cfmain -O3 -march=native cfmain.f cfsubdc.o",
   "./cfmain",
   2000000,
   "rm -f cfmain cfsubdc.o"]

JuliaBcast = [
   "Julia : broadcast",
   "julia",
   "",
   "",
   "julia csubbcast.jl",
   1500000,
   ""]

JuliaBcastO3 = [
   "Julia : broadcast",
   "julia -O3",
   "",
   "",
   "julia -O3 csubbcast.jl",
   1500000,
   ""]

JavascriptFlat = [
   "Javascript : flat",
   "Node.js",
   "",
   "",
   "node cjstestflat.js",
   400000,
   ""]

JavascriptFlatBun = [
   "Javascript : flat",
   "Bun",
   "",
   "",
   "bun cjstestflat.js",
   500000,
   ""]

JavascriptFlatDeno = [
   "Javascript : flat",
   "Deno",
   "",
   "",
   "deno run cjstestflat.js",
   200000,
   ""]

SwiftGridO = [
   "Swift : grid",
   "Swiftc -O",
   "xcrun swiftc -o /tmp/cstestgrid -O cstestgrid.swift",
   "",
   "/tmp/cstestgrid",
   400000,
   "rm -f /tmp/cstestgrid"]

SwiftGridOunchecked = [
   "Swift : grid",
   "Swiftc -Ounchecked",
   "xcrun swiftc -o /tmp/cstestgrid -Ounchecked cstestgrid.swift",
   "",
   "/tmp/cstestgrid",
   2000000,
   "rm -f /tmp/cstestgrid"]

#  ------------------------------------------------------------------------------
#  2026 idiom review. Variants implemented from two independent expert reviews
#  of the kernels (review/recommendations-fable.md and recommendations-chatgpt.md,
#  outside this repo), one group of languages per file in review/impl/. Each test
#  is paired with the existing test it improves on (review/impl/pairs.json).

#  --- from 01-c-family.py ---

#  NEON kernel with v8-v11 (callee-saved) renamed to v26-v29; otherwise identical
AssemblerABI = [
   "Assembler : ABI fixed",
   "clang (arm64)",
   "c++ -c -o /tmp/cnrsub_arm_abi.o cnrsub_arm_abi.s",
   "c++ -o /tmp/assmain_abi -O cnrmain.cpp /tmp/cnrsub_arm_abi.o",
   "/tmp/assmain_abi",
   4000000,
   "rm -f /tmp/assmain_abi /tmp/cnrsub_arm_abi.o"]

#  node --no-liftoff: skip the baseline wasm tier
WasmNodeNoLiftoff = [
   "C : raw",
   "wasm Node no-liftoff",
   "zig cc -target wasm32-wasi -O3 -fno-exceptions -x c++ cmain.cpp csub.cpp -o /tmp/csub_nl.wasm",
   "",
   "node --no-liftoff wasirun.mjs /tmp/csub_nl.wasm",
   250000,
   "rm -f /tmp/csub_nl.wasm"]

#  node --no-liftoff --experimental-wasm-simd-opt for the SIMD build
WasmNodeSimdNoLiftoff = [
   "C : raw",
   "wasm simd Node nolft",
   "zig cc -target wasm32-wasi -O3 -msimd128 -fno-exceptions -x c++ cmain.cpp csub.cpp -o /tmp/csub_simd_nl.wasm",
   "",
   "node --no-liftoff --experimental-wasm-simd-opt wasirun.mjs /tmp/csub_simd_nl.wasm",
   400000,
   "rm -f /tmp/csub_simd_nl.wasm"]

#  float64 twin of the single-add kernel
RawCdsingleO3 = [
   "C : raw dbl single-add",
   "clang -O3",
   "c++ -c -O3 csubsd.cpp -o /tmp/csubsd.o",
   "c++ -o /tmp/cmainsd -O3 cmaind.cpp /tmp/csubsd.o",
   "/tmp/cmainsd",
   1200000,
   "rm -f /tmp/cmainsd /tmp/csubsd.o"]

#  in + float(Ix+Iy): one conversion and one float add per element, as the assembler does
RawCsingleO3 = [
   "C : raw single-add",
   "clang -O3",
   "c++ -c -O3 csubs.cpp -o /tmp/csubs.o",
   "c++ -o /tmp/cmains -O3 cmain.cpp /tmp/csubs.o",
   "/tmp/cmains",
   3000000,
   "rm -f /tmp/cmains /tmp/csubs.o"]

#  __restrict__ row pointers, Keith's two rounded adds kept
RawCrestrictO3native = [
   "C : raw restrict",
   "clang -O3 native",
   "c++ -O3 -march=native -c csubrestrict.cpp -o /tmp/csubrestrict.o",
   "c++ -O3 -march=native cmain.cpp /tmp/csubrestrict.o -o /tmp/cmainrestrict",
   "/tmp/cmainrestrict",
   3000000,
   "rm -f /tmp/csubrestrict.o /tmp/cmainrestrict"]

#  genuine C: C99 VLA parameters, Out[Iy][Ix] in the subroutine, built with cc
RawCvlaO3 = [
   "C : VLA",
   "cc -O3",
   "cc -std=c11 -c -O3 csub_vla.c -o /tmp/csub_vla.o",
   "cc -std=c11 -O3 -o /tmp/cmain_c cmain_c.c /tmp/csub_vla.o",
   "/tmp/cmain_c",
   3000000,
   "rm -f /tmp/cmain_c /tmp/csub_vla.o"]

#  the same C99 kernel under real GCC 15 with -march=native
RawCvlaGcc15O3native = [
   "C : VLA",
   "gcc-15 -O3 native",
   "/opt/homebrew/bin/gcc-15 -std=c11 -c -O3 -march=native csub_vla.c -o /tmp/csub_vla_g.o",
   "/opt/homebrew/bin/gcc-15 -std=c11 -O3 -march=native -o /tmp/cmain_c_g cmain_c.c /tmp/csub_vla_g.o",
   "/tmp/cmain_c_g",
   3000000,
   "rm -f /tmp/cmain_c_g /tmp/csub_vla_g.o"]

#  real GCC 15 instead of /usr/bin/g++ (which is Apple clang)
RawCgcc15O3native = [
   "C : raw",
   "g++-15 -O3 native",
   "/opt/homebrew/bin/g++-15 -c -O3 -march=native csub.cpp -o /tmp/csub_g15.o",
   "/opt/homebrew/bin/g++-15 -o /tmp/cmain_g15 -O3 -march=native cmain.cpp /tmp/csub_g15.o",
   "/tmp/cmain_g15",
   3000000,
   "rm -f /tmp/cmain_g15 /tmp/csub_g15.o"]

#  real GCC 15 for the Boost kernel
BoostCgcc15O3nativeNoAssert = [
   "C++ : Boost no assert",
   "g++-15 -O3 native",
   "/opt/homebrew/bin/g++-15 -c -O3 -march=native -DBOOST_DISABLE_ASSERTS cbsub.cpp -o /tmp/cbsub_g15.o",
   "/opt/homebrew/bin/g++-15 -o /tmp/cbmain_g15 -O3 -march=native -DBOOST_DISABLE_ASSERTS cbmain.cpp /tmp/cbsub_g15.o",
   "/tmp/cbmain_g15",
   1000000,
   "rm -f /tmp/cbmain_g15 /tmp/cbsub_g15.o"]

#  int loop counters instead of multi_array::index (ptrdiff_t); -DNDEBUG
BoostCintO3NoAssert = [
   "C++ : Boost int idx",
   "clang -O3",
   "c++ -c -O3 -DNDEBUG cbsubi.cpp -o /tmp/cbsubi.o",
   "c++ -o /tmp/cbmaini -O3 -DNDEBUG cbmain.cpp /tmp/cbsubi.o",
   "/tmp/cbmaini",
   3000000,
   "rm -f /tmp/cbmaini /tmp/cbsubi.o"]

#  scan multi_array storage through .data() instead of [][] proxies
BoostCdataO3native = [
   "C++ : Boost direct data",
   "clang -O3 native",
   "c++ -O3 -march=native -c cbsubdata.cpp -o /tmp/cbsubdata.o",
   "c++ -O3 -march=native cbmain.cpp /tmp/cbsubdata.o -o /tmp/cbmaindata",
   "/tmp/cbmaindata",
   3000000,
   "rm -f /tmp/cbsubdata.o /tmp/cbmaindata"]

#  C++23 std::mdspan 2D view instead of Boost.MultiArray
CppMdspanO3 = [
   "C++ : mdspan",
   "clang -O3",
   "c++ -std=c++23 -c -O3 cmdsub.cpp -o /tmp/cmdsub.o",
   "c++ -std=c++23 -o /tmp/cmdmain -O3 cmdmain.cpp /tmp/cmdsub.o",
   "/tmp/cmdmain",
   3000000,
   "rm -f /tmp/cmdmain /tmp/cmdsub.o"]

#  real GCC 15 for the row-pointer kernel
CNumRgcc15O3native = [
   "C : Num. rec.",
   "g++-15 -O3 native",
   "/opt/homebrew/bin/g++-15 -c -O3 -march=native cnrsub.cpp -o /tmp/cnrsub_g15.o",
   "/opt/homebrew/bin/g++-15 -o /tmp/cnrmain_g15 -O3 -march=native cnrmain.cpp /tmp/cnrsub_g15.o",
   "/tmp/cnrmain_g15",
   3000000,
   "rm -f /tmp/cnrmain_g15 /tmp/cnrsub_g15.o"]

#  --- from 02-python.py ---

#  lists filled with floats instead of Python ints
Python3FloatLists = [
   "Python : lists",
   "Python3 float",
   "",
   "",
   "python3 csubrawf.py",
   6000,
   ""]

#  row lists bound once per row, enumerate() inner loop
Python3Rows = [
   "Python : lists rows",
   "Python3",
   "",
   "",
   "python3 csubraw_rows.py",
   6500,
   ""]

#  ndarray.item() reads return Python floats, not numpy scalars
Python3npItem = [
   "Python : numpy raw",
   "Python3 .item()",
   "",
   "",
   "python3 csubnpitem.py",
   2300,
   ""]

#  float index vector, numpy.add(out=row), in-place += (drops the 0-d numpy.array(nx) oddity)
Python3vec2 = [
   "Python : vectors",
   "Python3 in-place",
   "",
   "",
   "python3 csubnpv2.py",
   350000,
   ""]

#  whole-array in place: numpy.add(out=out) then +=, float index vectors, no temporaries
Python3ary2 = [
   "Python : arrays",
   "Python3 in-place",
   "",
   "",
   "python3 csubnpna2.py",
   300000,
   ""]

#  the in-place whole-array form in float32
Python3ary32 = [
   "Python : arrays",
   "Python3 in-place f32",
   "",
   "",
   "python3 csubnpna32.py",
   550000,
   ""]

#  numba kernel on float32 arrays with a float32 index cast
Python3npNumba32 = [
   "Python : numpy raw",
   "Python3 numba f32",
   "",
   "",
   "python3 csubnp-numba32.py",
   1600000,
   ""]

#  lists filled with floats instead of Python ints
PyPyFloatLists = [
   "Python : lists",
   "PyPy3 float",
   "",
   "",
   "pypy3 csubrawf.py",
   120000,
   ""]

#  row lists bound once per row, enumerate() inner loop
PyPyRows = [
   "Python : lists rows",
   "PyPy3",
   "",
   "",
   "pypy3 csubraw_rows.py",
   250000,
   ""]

#  lists filled with floats instead of Python ints
GraalPyFloatLists = [
   "Python : lists",
   "GraalPy float",
   "",
   "",
   "graalpy csubrawf.py",
   300000,
   ""]

#  Keith's csubnp.py compiled by Codon with its native numpy (bounds-checked ndarray indexing)
CodonNumpy = [
   "Python : numpy raw",
   "Codon",
   "codon-pybuild-np csubnp.py /tmp/csub_codon_np",
   "",
   "/tmp/csub_codon_np",
   550000,
   "rm -f /tmp/csub_codon_np"]

#  the Codon numpy build with --disable-exceptions (no IndexError paths; inner loop vectorises); baseline is itself new, CodonLists is the existing reference
CodonNumpyNoExc = [
   "Python : numpy raw",
   "Codon no exceptions",
   "codon-pybuild-np csubnp.py /tmp/csub_codon_npne --disable-exceptions",
   "",
   "/tmp/csub_codon_npne",
   1500000,
   "rm -f /tmp/csub_codon_npne"]

#  same kernel compiled -O3 -mcpu=native instead of inherited -O2
CythonNative = [
   "Python : numpy raw",
   "Cython -O3 native",
   "pyext-python -m Cython.Build.Cythonize -i -3 csubcy_native.pyx",
   "",
   "pyext-python csubext.py csubcy_native",
   1100000,
   "rm -rf csubcy_native.c csubcy_native.cpython-314-darwin.so build"]

#  float memoryviews and Py_ssize_t indices; same unchecked kernel
CythonF32 = [
   "Python : numpy raw",
   "Cython typed f32",
   "pyext-python -m Cython.Build.Cythonize -i -3 csubcy_f32.pyx",
   "",
   "pyext-python csubext32.py csubcy_f32",
   1500000,
   "rm -rf csubcy_f32.c csubcy_f32.cpython-314-darwin.so build"]

#  same kernel built with -O3 -mcpu=native
PythranNative = [
   "Python : numpy raw",
   "Pythran -O3 native",
   "pyext-python -m pythran.run -O3 -mcpu=native csubptn.py",
   "",
   "pyext-python csubext.py csubptn",
   1400000,
   "rm -f csubptn.cpython-314-darwin.so"]

#  float32 export with a float32 index cast
PythranF32 = [
   "Python : numpy raw",
   "Pythran f32",
   "pyext-python -m pythran.run -O3 csubpt32.py",
   "",
   "pyext-python csubext32.py csubpt32",
   1500000,
   "rm -f csubpt32.cpython-314-darwin.so"]

#  --- from 03-array-languages.py ---

#  same cfsub.f; -funroll-loops gives an 8-vector NEON loop body instead of one vector per iteration
FortranUnroll = [
   "Fortran",
   "gfortran -O3 unroll",
   "gfortran -c -o /tmp/cfsub_unroll.o -O3 -march=native -funroll-loops cfsub.f",
   "gfortran -o /tmp/cfmain_unroll -O3 -march=native -funroll-loops cfmain.f /tmp/cfsub_unroll.o",
   "/tmp/cfmain_unroll",
   2500000,
   "rm -f /tmp/cfmain_unroll /tmp/cfsub_unroll.o"]

#  F90 array sections one column at a time, no spread() temporaries; the Fortran whole-array idiom an expert would write
FortranCol = [
   "Fortran : sections",
   "gfortran -O3 native",
   "gfortran -c -o /tmp/cfsubcol.o -O3 -march=native cfsubcol.f90",
   "gfortran -o /tmp/cfmain_col -O3 -march=native cfmain.f /tmp/cfsubcol.o",
   "/tmp/cfmain_col",
   1500000,
   "rm -f /tmp/cfmain_col /tmp/cfsubcol.o"]

#  double precision twin of Keith's float32 cfsub.f/cfmain.f, for comparison with the float64 ports
FortranDouble = [
   "Fortran : double",
   "gfortran -O3 native",
   "gfortran -c -o /tmp/cfsubd.o -O3 -march=native cfsubd.f",
   "gfortran -o /tmp/cfmaind -O3 -march=native cfmaind.f /tmp/cfsubd.o",
   "/tmp/cfmaind",
   1200000,
   "rm -f /tmp/cfmaind /tmp/cfsubd.o"]

#  output in an environment, filled in place and written back once per call; csubref.r copies the whole matrix per element store
REnv = [
   "R : env ref",
   "Rscript",
   "",
   "",
   "Rscript csubenv.r",
   4000,
   ""]

#  column-major recycling plus rep(each=) instead of outer(); index work still done per call
RRecyc = [
   "R : recycle",
   "Rscript",
   "",
   "",
   "Rscript csubrecyc.r",
   35000,
   ""]

#  ChatGPT: zero-based coordinate vectors hoisted, two input-dependent adds per call (MATLAB/Octave convention)
RCoords = [
   "R : coords",
   "Rscript",
   "",
   "",
   "Rscript csubcoords.r",
   100000,
   ""]

#  (nx,ny) layout so the inner loop is unit-stride, as in the other column-major ports
MatlabLoopC = [
   "MATLAB : loop (nx,ny)",
   "matlab loop",
   "",
   "",
   "matlab-run csubrawc_ml",
   250000,
   ""]

#  single-precision twin of csubraw_ml.m
MatlabLoopS = [
   "MATLAB : single",
   "matlab loop",
   "",
   "",
   "matlab-run csubraws_ml",
   250000,
   ""]

#  ChatGPT: (nx,ny) layout, single arrays, zero-based single coordinates, maxNumCompThreads(1) inside the function
MatlabSingle = [
   "MATLAB : single (nx,ny)",
   "matlab serial loop",
   "",
   "",
   "matlab-run csubsingle_ml",
   250000,
   ""]

#  same csubraw_ml.m started with matlab -singleCompThread (new wrapper bin/matlab-run-1t)
MatlabLoop1t = [
   "MATLAB",
   "matlab loop 1 thread",
   "",
   "",
   "matlab-run-1t csubraw_ml",
   250000,
   ""]

#  single-precision twin of csubvec_ml.m
MatlabVecS = [
   "MATLAB : single",
   "matlab vectorised",
   "",
   "",
   "matlab-run csubvecs_ml",
   400000,
   ""]

#  same csubvec_ml.m started with matlab -singleCompThread (new wrapper bin/matlab-run-1t)
MatlabVec1t = [
   "MATLAB",
   "matlab vec 1 thread",
   "",
   "",
   "matlab-run-1t csubvec_ml",
   400000,
   ""]

#  index arrays built on every call (lindgen mod/div); csubvec_gdl.pro precomputes the whole ix+iy matrix so only one add is timed
GDLVec2 = [
   "GDL : vec per-call idx",
   "gdl vectorised",
   "",
   "",
   "gdl-run csubvec2_gdl",
   120000,
   ""]

#  single-precision twin of csubvec_gdl.pro (same precomputed index matrix)
GDLVecF = [
   "GDL : single",
   "gdl vectorised",
   "",
   "",
   "gdl-run csubvecf_gdl",
   1200000,
   ""]

#  ChatGPT: single precision, two separate precomputed coordinate planes, (ina+xx)+yy per call, cpu tpool_nthreads=1
GDLSingle = [
   "GDL : single 2 adds",
   "gdl serial array",
   "",
   "",
   "gdl-run csubsingle_gdl",
   500000,
   ""]

#  Keith's csub.jl with @inbounds only (Int64 counters), to separate bounds checks from the int32 effect in csubint32nb.jl
JuliaNB = [
   "Julia",
   "julia (inbounds)",
   "",
   "",
   "julia -O3 csubnb.jl",
   1500000,
   ""]

#  same int32 @inbounds kernel; driver in a main() function so the repeat loop is a static call, not dynamic dispatch on globals
JuliaMain32 = [
   "Julia",
   "julia (int32, main)",
   "",
   "",
   "julia -O3 csubmain32.jl",
   3000000,
   ""]

#  Float64 twin of csubint32nb.jl
JuliaF64 = [
   "Julia : double",
   "julia (int32)",
   "",
   "",
   "julia -O3 csubf64.jl",
   1300000,
   ""]

#  broadcast kernel with Int32 index ranges: four int32->Float32 lanes per NEON vector instead of two int64
JuliaBcast32 = [
   "Julia : broadcast i32",
   "julia",
   "",
   "",
   "julia csubbcast32.jl",
   3000000,
   ""]

#  (nx,ny) layout twin of csubrawc_ml.m; unit-stride inner loop (expected to make no measurable difference without a JIT)
OctaveLoopC = [
   "Octave : loop (nx,ny)",
   "octave loop",
   "",
   "",
   "octave-cli --no-gui --norc -q csubrawc.m",
   80,
   ""]

#  single-precision twin of csubvec.m (also covers ChatGPT's csubsingle.m proposal)
OctaveVecS = [
   "Octave : single",
   "octave vectorised",
   "",
   "",
   "octave-cli --no-gui --norc -q csubvecs.m",
   60000,
   ""]

#  input offset by 0.5 so ina/out are float64 (3!:0 = 8); csubraw.ijs is an int64 test with overflow-checked adds
JFloat = [
   "J : float",
   "jconsole",
   "",
   "",
   "jconsole csubflt.ijs",
   450000,
   ""]

#  as JFloat, but the addition table is built directly as floats so the kernel add needs no int-to-float conversion
JFloatIdx = [
   "J : float idx",
   "jconsole",
   "",
   "",
   "jconsole csubfltidx.ijs",
   550000,
   ""]

#  J element-by-element loop with { fetch and } amend, on float data; J's counterpart of csubraw.apls
JLoop = [
   "J : loop",
   "jconsole",
   "",
   "",
   "jconsole csubloop.ijs",
   900,
   ""]

#  rank-operator form (⍳nx)+⍤1 then (⍳ny)+⍤0 1: no ny×nx index table formed; sizing runs suggest it is slower than ∘.+
AplRank = [
   "APL",
   "dyalog rank",
   "",
   "",
   "dyalogscript csubrank.apls",
   270000,
   ""]

#  one row per :For iteration, each row a single vector expression (the 'vectors' form)
AplRow = [
   "APL : rows",
   "dyalog loop",
   "",
   "",
   "dyalogscript csubrow.apls",
   100000,
   ""]

#  --- from 04-compiled.py ---

#  flat [Float] via unsafe buffer pointers, Int32 index sum with &+: vectorises at -O (both reviews; Fable's Int32 form)
SwiftFlat32O = [
   "Swift : flat32",
   "Swiftc -O",
   "xcrun swiftc -o /tmp/cstestflat32 -O cstestflat32.swift",
   "",
   "/tmp/cstestflat32",
   2100000,
   "rm -f /tmp/cstestflat32"]

#  same kernel at -Ounchecked: index converted 4 lanes at a time instead of 2
SwiftFlat32Ounchecked = [
   "Swift : flat32",
   "Swiftc -Ounchecked",
   "xcrun swiftc -o /tmp/cstestflat32 -Ounchecked cstestflat32.swift",
   "",
   "/tmp/cstestflat32",
   2800000,
   "rm -f /tmp/cstestflat32"]

#  flat [Float] via unsafe buffer pointers, Int indices, Float(Ix)+Float(Iy) (ChatGPT 'scoped buffers' / Fable 'flat pointers')
SwiftBufO = [
   "Swift : buffers",
   "Swiftc -O",
   "xcrun swiftc -o /tmp/cstestbuf -O cstestbuf.swift",
   "",
   "/tmp/cstestbuf",
   1500000,
   "rm -f /tmp/cstestbuf"]

#  same buffer kernel at -Ounchecked (control: should tie cstestflat -Ounchecked)
SwiftBufOunchecked = [
   "Swift : buffers",
   "Swiftc -Ounchecked",
   "xcrun swiftc -o /tmp/cstestbuf -Ounchecked cstestbuf.swift",
   "",
   "/tmp/cstestbuf",
   1500000,
   "rm -f /tmp/cstestbuf"]

#  Keith's [[Float]] layout, row hoisted once per row (withUnsafeMutableBufferPointer)
SwiftRowsO = [
   "Swift : rows",
   "Swiftc -O",
   "xcrun swiftc -o /tmp/cstestrows -O cstestrows.swift",
   "",
   "/tmp/cstestrows",
   1450000,
   "rm -f /tmp/cstestrows"]

#  same row-hoisted nested kernel at -Ounchecked
SwiftRowsOunchecked = [
   "Swift : rows",
   "Swiftc -Ounchecked",
   "xcrun swiftc -o /tmp/cstestrows -Ounchecked cstestrows.swift",
   "",
   "/tmp/cstestrows",
   1400000,
   "rm -f /tmp/cstestrows"]

#  real(32) twin of csubraw.chpl (both reviews)
ChapelFast32 = [
   "Chapel : real(32)",
   "chpl --fast",
   "chpl --fast csubraw32.chpl -o /tmp/csub_chpl32",
   "",
   "/tmp/csub_chpl32",
   800000,
   "rm -f /tmp/csub_chpl32"]

#  flat List[Float64], raw pointer, explicit SIMD inner loop (Fable)
MojoSimd = [
   "Mojo : flat SIMD",
   "mojo build",
   "mojo build csubsimd.mojo -o /tmp/csub_mojosimd",
   "",
   "/tmp/csub_mojosimd",
   1250000,
   "rm -f /tmp/csub_mojosimd"]

#  Float32 twin of the flat SIMD kernel
MojoSimd32 = [
   "Mojo : flat SIMD f32",
   "mojo build",
   "mojo build csubsimd32.mojo -o /tmp/csub_mojosimd32",
   "",
   "/tmp/csub_mojosimd32",
   2400000,
   "rm -f /tmp/csub_mojosimd32"]

#  List[List] layout kept, row pointers taken once per row (Fable)
MojoPtr = [
   "Mojo : rows ptr",
   "mojo build",
   "mojo build csubptr.mojo -o /tmp/csub_mojoptr",
   "",
   "/tmp/csub_mojoptr",
   730000,
   "rm -f /tmp/csub_mojoptr"]

#  Float32 twin of csubraw.mojo, -D ASSERT=none (ChatGPT)
MojoLists32 = [
   "Mojo : lists f32",
   "mojo -D ASSERT=none",
   "mojo build -D ASSERT=none csubraw32.mojo -o /tmp/csub_mojo32",
   "",
   "/tmp/csub_mojo32",
   500000,
   "rm -f /tmp/csub_mojo32"]

#  one Vec<f32>, chunks_exact/zip iterators (both reviews; reads nrpt nx ny)
RustFlat = [
   "Rust : flat",
   "Rustc -O3 native",
   "rustc -C target-cpu=native -C opt-level=3 crsflat.rs -o /tmp/crsflat",
   "",
   "/tmp/crsflat",
   700000,
   "rm -f /tmp/crsflat"]

#  flat kernel with index sum narrowed to u32 before conversion (Fable)
RustFlat32idx = [
   "Rust : flat u32 idx",
   "Rustc -O3 native",
   "rustc -C target-cpu=native -C opt-level=3 crsflat32.rs -o /tmp/crsflat32",
   "",
   "/tmp/crsflat32",
   3200000,
   "rm -f /tmp/crsflat32"]

#  Vec<Vec<f32>> indexed with bounds checks proved away by slicing, no unsafe (Fable)
RustRows = [
   "Rust : rows safe",
   "Rustc -O3 native",
   "rustc -C target-cpu=native -C opt-level=3 crsrows.rs -o /tmp/crsrows",
   "",
   "/tmp/crsrows",
   700000,
   "rm -f /tmp/crsrows"]

#  range over input row + re-sliced output row: bounds checks dropped without -B (both reviews)
GoRange = [
   "Go : range",
   "go",
   "go build -o /tmp/csub_gorange csubrange.go",
   "",
   "/tmp/csub_gorange",
   700000,
   "rm -f /tmp/csub_gorange"]

#  float32 twin of csubrange.go (ChatGPT's csubsingle.go)
GoRange32 = [
   "Go : range f32",
   "go",
   "go build -o /tmp/csub_gorange32 csubrange32.go",
   "",
   "/tmp/csub_gorange32",
   720000,
   "rm -f /tmp/csub_gorange32"]

#  Slice(Float32) twin of csubraw.cr (both reviews)
Crystal32 = [
   "Crystal : f32",
   "crystal --release",
   "crystal build --release -o /tmp/csub_cr32 csubraw32.cr",
   "",
   "/tmp/csub_cr32",
   2700000,
   "rm -f /tmp/csub_cr32 /tmp/csub_cr32.dwarf"]

#  rows walked through Slice#to_unsafe pointers (Fable; expected small)
CrystalPtr = [
   "Crystal : ptr rows",
   "crystal --release",
   "crystal build --release -o /tmp/csub_crptr csubptr.cr",
   "",
   "/tmp/csub_crptr",
   1200000,
   "rm -f /tmp/csub_crptr /tmp/csub_crptr.dwarf"]

#  f32 with multi-object for loops (both reviews proposed f32; Fable's loop form)
Zig32 = [
   "Zig : f32",
   "zig -O ReleaseFast",
   "zig build-exe -O ReleaseFast csubraw_f32.zig -femit-bin=/tmp/csub_zig32",
   "",
   "/tmp/csub_zig32",
   1550000,
   "rm -f /tmp/csub_zig32 /tmp/csub_zig32.o"]

#  f64 control for the multi-object for loop form (Fable)
ZigFor = [
   "Zig : for",
   "zig -O ReleaseFast",
   "zig build-exe -O ReleaseFast csubfor.zig -femit-bin=/tmp/csub_zigfor",
   "",
   "/tmp/csub_zigfor",
   1250000,
   "rm -f /tmp/csub_zigfor /tmp/csub_zigfor.o"]

#  float twin of csubraw.d (both reviews)
DLang32 = [
   "D : float",
   "ldc2 -O3 -release",
   "ldc2 -O3 -release -boundscheck=off csubraw32.d -of=/tmp/csub_d32 -od=/tmp",
   "",
   "/tmp/csub_d32",
   1550000,
   "rm -f /tmp/csub_d32 /tmp/csub_d32.o"]

#  csubraw.d with -mcpu=native (Fable)
DLangNative = [
   "D",
   "ldc2 -O3 mcpu=native",
   "ldc2 -O3 -release -boundscheck=off -mcpu=native csubraw.d -of=/tmp/csub_dnat -od=/tmp",
   "",
   "/tmp/csub_dnat",
   1250000,
   "rm -f /tmp/csub_dnat /tmp/csub_dnat.o"]

#  rows as ptr UncheckedArray; csubraw.nim's loop is scalar (Fable)
NimRowsPtr = [
   "Nim : rows ptr",
   "nim -d:danger",
   "nim c -d:danger --mm:arc --hints:off --nimcache:/tmp/csub_nimrp_cache -o:/tmp/csub_nimrp csubrowsptr.nim",
   "",
   "/tmp/csub_nimrp",
   1150000,
   "rm -rf /tmp/csub_nimrp /tmp/csub_nimrp_cache"]

#  float32 twin of csubrowsptr.nim
NimRowsPtr32 = [
   "Nim : rows ptr f32",
   "nim -d:danger",
   "nim c -d:danger --mm:arc --hints:off --nimcache:/tmp/csub_nimrp32_cache -o:/tmp/csub_nimrp32 csubrowsptr32.nim",
   "",
   "/tmp/csub_nimrp32",
   1600000,
   "rm -rf /tmp/csub_nimrp32 /tmp/csub_nimrp32_cache"]

#  flat seq passed as openArray (Fable)
NimFlat = [
   "Nim : flat",
   "nim -d:danger",
   "nim c -d:danger --mm:arc --hints:off --nimcache:/tmp/csub_nimflat_cache -o:/tmp/csub_nimflat csubflat.nim",
   "",
   "/tmp/csub_nimflat",
   1350000,
   "rm -rf /tmp/csub_nimflat /tmp/csub_nimflat_cache"]

#  float32 twin of csubflat.nim
NimFlat32 = [
   "Nim : flat f32",
   "nim -d:danger",
   "nim c -d:danger --mm:arc --hints:off --nimcache:/tmp/csub_nimflat32_cache -o:/tmp/csub_nimflat32 csubflat32.nim",
   "",
   "/tmp/csub_nimflat32",
   1550000,
   "rm -rf /tmp/csub_nimflat32 /tmp/csub_nimflat32_cache"]

#  float32 twin of csubraw.nim, read-only input param, --mm:arc (ChatGPT)
Nim32 = [
   "Nim : f32",
   "nim -d:danger",
   "nim c -d:danger --mm:arc --hints:off --nimcache:/tmp/csub_nim32_cache -o:/tmp/csub_nim32 csubraw32.nim",
   "",
   "/tmp/csub_nim32",
   1600000,
   "rm -rf /tmp/csub_nim32 /tmp/csub_nim32_cache"]

#  csubraw.nim with --passC:-mcpu=native for clang (Fable group note)
NimNative = [
   "Nim",
   "nim -d:danger native",
   "nim c -d:danger --mm:arc --hints:off --passC:-mcpu=native --nimcache:/tmp/csub_nimnat_cache -o:/tmp/csub_nimnat csubraw.nim",
   "",
   "/tmp/csub_nimnat",
   1150000,
   "rm -rf /tmp/csub_nimnat /tmp/csub_nimnat_cache"]

#  'Range loops and Long_Float(Ix)+Long_Float(Iy): checked build vectorises (Fable)
AdaRngO3 = [
   "Ada : 'Range",
   "gnatmake -O3",
   "gnatmake -q -f -O3 csubrng.adb -o /tmp/csub_adarng -D /tmp",
   "",
   "/tmp/csub_adarng",
   800000,
   "rm -f /tmp/csub_adarng /tmp/csubrng.ali /tmp/csubrng.o"]

#  same kernel with -gnatp (control)
AdaRngO3gnatp = [
   "Ada : 'Range",
   "gnatmake -O3 -gnatp",
   "gnatmake -q -f -O3 -gnatp csubrng.adb -o /tmp/csub_adarng -D /tmp",
   "",
   "/tmp/csub_adarng",
   800000,
   "rm -f /tmp/csub_adarng /tmp/csubrng.ali /tmp/csubrng.o"]

#  Float (32-bit) twin of csubrng.adb, checks on
AdaRng32O3 = [
   "Ada : 'Range f32",
   "gnatmake -O3",
   "gnatmake -q -f -O3 csubrng32.adb -o /tmp/csub_adarng32 -D /tmp",
   "",
   "/tmp/csub_adarng32",
   1600000,
   "rm -f /tmp/csub_adarng32 /tmp/csubrng32.ali /tmp/csubrng32.o"]

#  Float (32-bit) twin of csubrng.adb, -gnatp
AdaRng32O3gnatp = [
   "Ada : 'Range f32",
   "gnatmake -O3 -gnatp",
   "gnatmake -q -f -O3 -gnatp csubrng32.adb -o /tmp/csub_adarng32 -D /tmp",
   "",
   "/tmp/csub_adarng32",
   1600000,
   "rm -f /tmp/csub_adarng32 /tmp/csubrng32.ali /tmp/csubrng32.o"]

#  Float twin of csubraw.adb, original loop form, -gnatp (ChatGPT)
Ada32gnatp = [
   "Ada : f32",
   "gnatmake -O3 -gnatp",
   "gnatmake -q -f -O3 -gnatp csubraw32.adb -o /tmp/csub_ada32 -D /tmp",
   "",
   "/tmp/csub_ada32",
   1600000,
   "rm -f /tmp/csub_ada32 /tmp/csubraw32.ali /tmp/csubraw32.o"]

#  csubraw.adb -O3 -gnatp with -mcpu=native (Fable)
AdaNative = [
   "Ada",
   "gnatp -mcpu=native",
   "gnatmake -q -f -O3 -gnatp -mcpu=native csubraw.adb -o /tmp/csub_adanat -D /tmp",
   "",
   "/tmp/csub_adanat",
   800000,
   "rm -f /tmp/csub_adanat /tmp/csubraw.ali /tmp/csubraw.o"]

#  --- from 05-vm.py ---

#  persistent vectors built via transient/assoc!/persistent! instead of per-element persistent assoc
ClojureTrans = [
   "Clojure : transients",
   "clojure",
   "",
   "",
   "clojure -M csubtrans.clj",
   14000,
   ""]

#  float[][] (float32 storage; arithmetic widened to double, narrowed on store) with *unchecked-math*
ClojureArrF32 = [
   "Clojure : arrays f32",
   "clojure",
   "",
   "",
   "clojure -M csubarrf32.clj",
   700000,
   ""]

#  Keith's kernel on double[][] for like-for-like comparison with the float64 ports
JavaDouble = [
   "Java : double",
   "Java",
   "javac -g:none csubd.java",
   "",
   "java csubd",
   800000,
   "rm -f csubd.class"]

#  explicit SIMD with jdk.incubator.vector FloatVector (4 lanes), float32
JavaVector = [
   "Java : Vector API",
   "Java",
   "javac -g:none --add-modules jdk.incubator.vector csubvec.java",
   "",
   "java --add-modules jdk.incubator.vector csubvec",
   1800000,
   "rm -f csubvec.class"]

#  interpreter-only JVM (-Xint), the no-JIT control
JavaXint = [
   "Java",
   "java -Xint",
   "javac -g:none csub.java",
   "",
   "java -Xint csub",
   14000,
   "rm -f csub.class"]

#  node --no-opt --no-maglev: Sparkplug baseline JIT only (--no-opt alone leaves Maglev on)
JavascriptBaseline = [
   "Javascript",
   "Node.js baseline",
   "",
   "",
   "node --no-opt --no-maglev cjstest.js",
   13000,
   ""]

#  node --no-opt --no-maglev --no-sparkplug: Ignition interpreter only
JavascriptInterp = [
   "Javascript",
   "Node.js interpreter",
   "",
   "",
   "node --no-opt --no-maglev --no-sparkplug cjstest.js",
   8500,
   ""]

#  Keith's nested Smi arrays with the row arrays hoisted out of the inner loop
JavascriptRows = [
   "Javascript : rows",
   "Node.js",
   "",
   "",
   "node cjstestrows.js",
   240000,
   ""]

#  same, Bun
JavascriptRowsBun = [
   "Javascript : rows",
   "Bun",
   "",
   "",
   "bun cjstestrows.js",
   340000,
   ""]

#  same, Deno
JavascriptRowsDeno = [
   "Javascript : rows",
   "Deno",
   "",
   "",
   "deno run cjstestrows.js",
   240000,
   ""]

#  nested Array of Float64Array rows (double[][] layout) vs one flat Float64Array
JavascriptTyped = [
   "Javascript : typed rows",
   "Node.js",
   "",
   "",
   "node cjstesttyped.js",
   330000,
   ""]

#  flat Float32Array, double arithmetic, float32 storage
JavascriptFlat32 = [
   "Javascript : flat f32",
   "Node.js",
   "",
   "",
   "node cjstestflat32.js",
   300000,
   ""]

#  flat Float32Array with Math.fround on every intermediate: true binary32 arithmetic
JavascriptFlat32R = [
   "Javascript : f32 round",
   "Node.js",
   "",
   "",
   "node cjstestflat32r.js",
   170000,
   ""]

#  same, Bun
JavascriptTypedBun = [
   "Javascript : typed rows",
   "Bun",
   "",
   "",
   "bun cjstesttyped.js",
   550000,
   ""]

#  same, Bun
JavascriptFlat32Bun = [
   "Javascript : flat f32",
   "Bun",
   "",
   "",
   "bun cjstestflat32.js",
   450000,
   ""]

#  same, Bun
JavascriptFlat32RBun = [
   "Javascript : f32 round",
   "Bun",
   "",
   "",
   "bun cjstestflat32r.js",
   500000,
   ""]

#  same, Deno
JavascriptTypedDeno = [
   "Javascript : typed rows",
   "Deno",
   "",
   "",
   "deno run cjstesttyped.js",
   160000,
   ""]

#  same, Deno
JavascriptFlat32Deno = [
   "Javascript : flat f32",
   "Deno",
   "",
   "",
   "deno run cjstestflat32.js",
   170000,
   ""]

#  float[][] twin of cs_proj
CSharpF32 = [
   "C# : float32",
   ".NET 8",
   "dotnet build cs_f32_proj -c Release -o /tmp/csf32bin --nologo -v q",
   "",
   "/tmp/csf32bin/cs_f32_proj",
   800000,
   "rm -rf /tmp/csf32bin"]

#  explicit SIMD with System.Numerics.Vector<double> (2 lanes); residual range checks on CopyTo
CSharpSIMD = [
   "C# : SIMD",
   ".NET 8",
   "dotnet build cs_simd_proj -c Release -o /tmp/cssimdbin --nologo -v q",
   "",
   "/tmp/cssimdbin/cs_simd_proj",
   1000000,
   "rm -rf /tmp/cssimdbin"]

#  float[][] twin of cs_aot_proj (Native AOT)
CSharpF32AOT = [
   "C# : float32",
   ".NET 8 AOT",
   "dotnet publish cs_f32_aot_proj -c Release -r osx-arm64 -o /tmp/csf32aotbin --nologo -v q",
   "",
   "/tmp/csf32aotbin/cs_f32_aot_proj",
   800000,
   "rm -rf /tmp/csf32aotbin"]

#  Native AOT with OptimizationPreference=Speed
CSharpAOTSpeed = [
   "C#",
   ".NET 8 AOT Speed",
   "dotnet publish cs_aot_speed_proj -c Release -r osx-arm64 -o /tmp/csaotspdbin --nologo -v q",
   "",
   "/tmp/csaotspdbin/cs_aot_speed_proj",
   650000,
   "rm -rf /tmp/csaotspdbin"]

#  while loops with < tests so RyuJIT clones the loop and removes the per-element range checks
FSharpWhile = [
   "F# : while",
   ".NET 8",
   "dotnet build fs_while_proj -c Release -o /tmp/fswbin --nologo -v q",
   "",
   "/tmp/fswbin/fs_while_proj",
   650000,
   "rm -rf /tmp/fswbin"]

#  float32[][] twin of fs_proj, keeping the for .. in range loops
FSharpF32 = [
   "F# : float32",
   ".NET 8",
   "dotnet build fs_f32_proj -c Release -o /tmp/fsf32bin --nologo -v q",
   "",
   "/tmp/fsf32bin/fs_f32_proj",
   550000,
   "rm -rf /tmp/fsf32bin"]

#  float32[][] with while loops
FSharpF32While = [
   "F# : while float32",
   ".NET 8",
   "dotnet build fs_f32_while_proj -c Release -o /tmp/fsf32wbin --nologo -v q",
   "",
   "/tmp/fsf32wbin/fs_f32_while_proj",
   800000,
   "rm -rf /tmp/fsf32wbin"]

#  Array<FloatArray> twin of csubraw.kt
KotlinF32 = [
   "Kotlin : float32",
   "kotlinc + JVM",
   "kotlinc csubf32.kt -include-runtime -d /tmp/csubf32_kt.jar",
   "",
   "java -jar /tmp/csubf32_kt.jar",
   900000,
   "rm -f /tmp/csubf32_kt.jar"]

#  one flat Float64List indexed iy*nx + ix
DartFlatJIT = [
   "Dart : flat",
   "dart run",
   "",
   "",
   "dart run csubflat.dart",
   340000,
   ""]

#  Float32List rows (float32 storage, double arithmetic), fixed-length row list
DartF32JIT = [
   "Dart : float32",
   "dart run",
   "",
   "",
   "dart run csubf32.dart",
   380000,
   ""]

#  same, dart compile exe
DartFlatAOT = [
   "Dart : flat",
   "dart compile exe",
   "dart compile exe csubflat.dart -o /tmp/csubflat_dart",
   "",
   "/tmp/csubflat_dart",
   250000,
   "rm -f /tmp/csubflat_dart"]

#  same, dart compile exe
DartF32AOT = [
   "Dart : float32",
   "dart compile exe",
   "dart compile exe csubf32.dart -o /tmp/csubf32_dart",
   "",
   "/tmp/csubf32_dart",
   250000,
   "rm -f /tmp/csubf32_dart"]

#  --- from 06-scripting.py ---

#  range foreach, row refs hoisted (data still integer-valued, as csubraw.pl)
PerlRows = [
   "Perl : rows",
   "Perl",
   "",
   "",
   "perl csubrows.pl",
   6000,
   ""]

#  direct AvARRAY indexing instead of av_fetch per element
PerlInlineAV2 = [
   "Perl : Inline::C AvARR",
   "Perl",
   "perl csubinlav2.pl 1 2000 10",
   "",
   "perl csubinlav2.pl",
   250000,
   "rm -rf /tmp/inline_csubinlav2"]

#  pack('f*') buffers and float kernel
PerlInlinePackedF32 = [
   "Perl : Inline::C f32",
   "Perl",
   "perl csubinlpk_f32.pl 1 2000 10",
   "",
   "perl csubinlpk_f32.pl",
   1200000,
   "rm -rf /tmp/inline_csubinlpk_f32"]

#  PDL::Core::at_bad_c/set_c called directly, no ->at/->set wrapper
PerlPDLrawXS = [
   "Perl/PDL : raw XS",
   "Perl/PDL",
   "",
   "",
   "perl csubpdlxs.pl",
   600,
   ""]

#  plus() into preallocated output + in-place broadcast add, no nx*ny temporaries
PerlPDLary2 = [
   "Perl/PDL : arrays2",
   "Perl/PDL",
   "",
   "",
   "perl csubpdlary2.pl",
   200000,
   ""]

#  the no-temporaries form with float ndarrays
PerlPDLary2F32 = [
   "Perl/PDL : arrays2 f32",
   "Perl/PDL",
   "",
   "",
   "perl csubpdlary2_f32.pl",
   200000,
   ""]

#  csubpdlary.pl with float ndarrays, same expression
PerlPDLaryF32 = [
   "Perl/PDL : arrays f32",
   "Perl/PDL",
   "",
   "",
   "perl csubpdlary_f32.pl",
   150000,
   ""]

#  PP kernel writes into preallocated output instead of allocating per call
PerlPDLpp2 = [
   "Perl/PDL : pp prealloc",
   "Perl/PDL",
   "perl csubpdlpp2.pl 1 2000 10",
   "",
   "perl csubpdlpp2.pl",
   1300000,
   "rm -rf /tmp/inline_csubpdlpp2"]

#  preallocated-output PP kernel on float ndarrays
PerlPDLpp2F32 = [
   "Perl/PDL : pp f32",
   "Perl/PDL",
   "perl csubpdlpp2_f32.pl 1 2000 10",
   "",
   "perl csubpdlpp2_f32.pl",
   1300000,
   "rm -rf /tmp/inline_csubpdlpp2_f32"]

#  nqp::atpos_n/bindpos_n on native num rows (Rakudo-specific)
RakuNqp = [
   "Raku : native nqp",
   "rakudo",
   "",
   "",
   "raku csubnqp.raku",
   10000,
   ""]

#  same, MVM_SPESH_DISABLE=1
RakuNqpNoSpesh = [
   "Raku : native nqp",
   "rakudo no spesh",
   "",
   "",
   "env MVM_SPESH_DISABLE=1 raku csubnqp.raku",
   8000,
   ""]

#  boxed AoA with row arrays bound once per iy
RakuRows = [
   "Raku : raw rows",
   "rakudo",
   "",
   "",
   "raku csubrows.raku",
   300,
   ""]

#  FFI double[] flat buffers instead of tables of tables
LuaFFI = [
   "Lua : FFI",
   "LuaJIT",
   "",
   "",
   "luajit csubffi.lua",
   600000,
   ""]

#  FFI float[] flat buffers
LuaFFIF32 = [
   "Lua : FFI f32",
   "LuaJIT",
   "",
   "",
   "luajit csubffi_f32.lua",
   600000,
   ""]

#  float-valued table elements (csubraw.lua stores integers)
LuaJITFloat = [
   "Lua : float",
   "LuaJIT",
   "",
   "",
   "luajit csubflt.lua",
   450000,
   ""]

#  float-valued table elements (csubraw.lua stores integers)
LuaPUCFloat = [
   "Lua : float",
   "lua 5.5",
   "",
   "",
   "lua csubflt.lua",
   18000,
   ""]

#  while loops instead of Integer#times blocks
RubyWhile33 = [
   "Ruby : while",
   "ruby 3.3",
   "",
   "",
   "ruby csubwhile.rb",
   5000,
   ""]

#  while loops instead of Integer#times blocks
RubyWhile33YJIT = [
   "Ruby : while",
   "ruby 3.3 +YJIT",
   "",
   "",
   "ruby --yjit csubwhile.rb",
   18000,
   ""]

#  while loops instead of Integer#times blocks
RubyWhile26 = [
   "Ruby : while",
   "ruby 2.6",
   "",
   "",
   "/usr/bin/ruby csubwhile.rb",
   5000,
   ""]

#  while loops instead of Integer#times blocks
RubyWhileTruffle = [
   "Ruby : while",
   "TruffleRuby",
   "",
   "",
   "truffleruby csubwhile.rb",
   350000,
   ""]

#  store + two inplace broadcast adds, no temporaries or []= path
RubyNumo2 = [
   "Ruby : Numo inplace",
   "ruby 3.3",
   "",
   "",
   "ruby csubnumo2.rb",
   250000,
   ""]

#  the inplace form on Numo::SFloat
RubyNumo2F32 = [
   "Ruby : Numo inpl f32",
   "ruby 3.3",
   "",
   "",
   "ruby csubnumo2_f32.rb",
   300000,
   ""]

#  csubnumo.rb on Numo::SFloat, same expression
RubyNumoF32 = [
   "Ruby : Numo f32",
   "ruby 3.3",
   "",
   "",
   "ruby csubnumo_f32.rb",
   190000,
   ""]

#  store + two inplace broadcast adds, no temporaries or []= path
RubyNumo2YJIT = [
   "Ruby : Numo inplace",
   "ruby 3.3 +YJIT",
   "",
   "",
   "ruby --yjit csubnumo2.rb",
   250000,
   ""]

#  braced expr (ctest.tcl's unbraced expr is re-parsed every call); double() input
TclBraced = [
   "Tcl : braced",
   "tclsh",
   "",
   "",
   "tclsh ctestbr.tcl",
   900,
   ""]

#  nested lists with lindex/lset instead of a string-keyed array; braced expr
TclLists = [
   "Tcl : lists",
   "tclsh",
   "",
   "",
   "tclsh ctestlst.tcl",
   1700,
   ""]

#  row arrays hoisted: input row by value, output row by reference
PHPRows = [
   "PHP : rows",
   "php 8.5",
   "",
   "",
   "php csubrows.php",
   30000,
   ""]

#  row arrays hoisted, tracing JIT
PHPRowsJIT = [
   "PHP : rows",
   "php 8.5 JIT",
   "",
   "",
   "php -d opcache.enable_cli=1 -d opcache.jit=tracing -d opcache.jit_buffer_size=64M csubrows.php",
   110000,
   ""]

#  opcache.jit=function instead of tracing, same csubraw.php
PHPJITfunc = [
   "PHP",
   "php 8.5 JIT function",
   "",
   "",
   "php -d opcache.enable_cli=1 -d opcache.jit=function -d opcache.jit_buffer_size=64M csubraw.php",
   20000,
   ""]

#  flat integer key iy*nx+ix instead of SUBSEP string key
MawkFlat = [
   "awk : flat",
   "mawk",
   "",
   "",
   "mawk -f csubflat.awk",
   4000,
   ""]

#  flat integer key iy*nx+ix instead of SUBSEP string key
GawkFlat = [
   "awk : flat",
   "gawk",
   "",
   "",
   "gawk -f csubflat.awk",
   2000,
   ""]

#  gawk arrays of arrays inp[iy][ix]
GawkAoA = [
   "awk : arrays of arrays",
   "gawk",
   "",
   "",
   "gawk -f csubaoa.awk",
   2000,
   ""]

#  declare -ai arrays, store inside (( )), running flat index
BashArith = [
   "bash : arith",
   "bash 5.3",
   "",
   "",
   "/opt/homebrew/bin/bash csubarith.sh",
   60,
   ""]

#  --- from 07-functional.py ---

#  packed float64 binary rows, recursive match/append, vs Erlang :array
ElixirBin = [
   "Elixir : binary",
   "elixir",
   "",
   "",
   "elixir csubbin.exs",
   4500,
   ""]

#  same binary kernel with ::float-32 storage
ElixirBin32 = [
   "Elixir : binary f32",
   "elixir",
   "",
   "",
   "elixir csubbin32.exs",
   4500,
   ""]

#  single body-recursive pass per row vs Enum.with_index |> Enum.map
ElixirMapRec = [
   "Elixir : map rec",
   "elixir",
   "",
   "",
   "elixir csubmap2.exs",
   4500,
   ""]

#  inner loop unrolled 4x (amortises OCaml 5 poll and tagged-int indexing)
OCamlUnroll = [
   "OCaml : unrolled",
   "ocamlopt -unsafe",
   "ocamlopt -unsafe csubunr.ml -o /tmp/csubunr_ml",
   "",
   "/tmp/csubunr_ml",
   1000000,
   "rm -f /tmp/csubunr_ml csubunr.cmi csubunr.cmx csubunr.o"]

#  flat Bigarray.Array1 float32 storage, double arithmetic
OCamlBigarray32 = [
   "OCaml : bigarray f32",
   "ocamlopt -unsafe",
   "ocamlopt -unsafe csubba32.ml -o /tmp/csubba32_ml",
   "",
   "/tmp/csubba32_ml",
   400000,
   "rm -f /tmp/csubba32_ml csubba32.cmi csubba32.cmx csubba32.o"]

#  immutable Array.mapi form allocating a new output each call
OCamlMapi = [
   "OCaml : mapi",
   "ocamlopt -unsafe",
   "ocamlopt -unsafe csubmapi.ml -o /tmp/csubmapi_ml",
   "",
   "/tmp/csubmapi_ml",
   90000,
   "rm -f /tmp/csubmapi_ml csubmapi.cmi csubmapi.cmx csubmapi.o"]

#  storage-vector indexing with hoisted row base vs 2D aref
SBCLFlat = [
   "Lisp : flat",
   "SBCL typed",
   "",
   "",
   "sbcl --script csubflat.lisp",
   600000,
   ""]

#  same flat kernel in single-float
SBCLFlat32 = [
   "Lisp : flat f32",
   "SBCL typed",
   "",
   "",
   "sbcl --script csubflat32.lisp",
   600000,
   ""]

#  existing 2D-aref typed kernel in single-float (ChatGPT)
SBCLTyped32 = [
   "Lisp : f32",
   "SBCL typed",
   "",
   "",
   "sbcl --script csubraw-typed32.lisp",
   400000,
   ""]

#  malloc'd Ptr Double, pointer-bump worker loop
HaskellPtr = [
   "Haskell : Ptr",
   "GHC -O2",
   "ghc -O2 csubptr.hs -o /tmp/csubptr_hs",
   "",
   "/tmp/csubptr_hs",
   450000,
   "rm -f /tmp/csubptr_hs csubptr.o csubptr.hi"]

#  same pointer kernel over Ptr Float
HaskellPtr32 = [
   "Haskell : Ptr f32",
   "GHC -O2",
   "ghc -O2 csubptr32.hs -o /tmp/csubptr32_hs",
   "",
   "/tmp/csubptr32_hs",
   450000,
   "rm -f /tmp/csubptr32_hs csubptr32.o csubptr32.hi"]

#  IOUArray Int Double, explicit workers, hoisted row base
HaskellArr = [
   "Haskell : IOUArray Int",
   "GHC -O2",
   "ghc -O2 csubarr.hs -o /tmp/csubarr_hs",
   "",
   "/tmp/csubarr_hs",
   300000,
   "rm -f /tmp/csubarr_hs csubarr.o csubarr.hi"]

#  existing forM_ kernel over IOUArray (Int,Int) Float (ChatGPT)
Haskell32 = [
   "Haskell : f32",
   "GHC -O2",
   "ghc -O2 csubraw32.hs -o /tmp/csubraw32_hs",
   "",
   "/tmp/csubraw32_hs",
   450000,
   "rm -f /tmp/csubraw32_hs csubraw32.o csubraw32.hi"]

#  generate-interrupt-trap #f, debug-level 0, unsafe variable refs
ChezNoTrap = [
   "Scheme : no trap",
   "chez opt-level 3",
   "",
   "",
   "chez --optimize-level 3 --script csubnotrap.ss",
   600000,
   ""]

#  bytevector IEEE-single rows, double arithmetic
ChezBV32 = [
   "Scheme : bytevector f32",
   "chez opt-level 3",
   "",
   "",
   "chez --optimize-level 3 --script csubbv32.ss",
   400000,
   ""]

FullTests = [
   Swift,SwiftOnone,SwiftO,SwiftOunchecked,Assembler,AssemblerABI,Fortran,
   FortranO,FortranO1,FortranO2,FortranO3,FortranO3native,FortranUnroll,
   RawR,Rref,REnv,Router,RRecyc,RCoords,Perl,PerlRows,PerlPDLraw,PerlPDLrawXS,
   PerlPDLvec,PerlPDLary,PerlPDLary2,PerlPDLary2F32,PerlPDLaryF32,PerlPDLpp,
   PerlPDLpp2,PerlPDLpp2F32,PerlInlineAV,PerlInlineAV2,PerlInlinePacked,
   PerlInlinePackedF32,RakuRaw,RakuRows,RakuRawNoSpesh,RakuNative,RakuNqp,
   RakuNativeNoSpesh,RakuNqpNoSpesh,RakuShaped,RakuHyper,MatlabLoop,MatlabLoopC,
   MatlabLoopS,MatlabSingle,MatlabLoop1t,MatlabVec,MatlabVecS,MatlabVec1t,
   GDLLoop,GDLVec,GDLVec2,GDLVecF,GDLSingle,ClojureVec,ClojureTrans,ClojureArr,
   ClojureArrF32,ElixirArray,ElixirMap,ElixirBin,ElixirBin32,ElixirMapRec,
   ChapelFast,Chapel,ChapelFast32,LuaPUC,LuaPUCFloat,Python3JIT,Python3npJIT,
   GraalPy,GraalPyFloatLists,GraalPyNumpy,TruffleRuby,RubyWhileTruffle,
   WasmWasmtime,WasmWasmtimeSimd,WasmNode,WasmNodeSimd,WasmNodeNoLiftoff,
   WasmNodeSimdNoLiftoff,Python2,Python2np,Python2vec,Python2ary,Python3,
   Python3FloatLists,Python3Rows,Python3np,Python3npItem,Python3vec,Python3vec2,
   Python3ary,Python3ary2,Python3ary32,Python3npNumba,Python3npNumba32,
   CodonLists,CodonNumpy,CodonNumpyNoExc,CythonUntyped,CythonTyped,CythonNative,
   CythonF32,CythonChecked,Pythran,PythranNative,PythranF32,Mojo,MojoNoAssert,
   MojoSimd,MojoSimd32,MojoPtr,MojoLists32,Rust,RustO,RustO3,RustO3native,
   RustO3nativeIter,RustO3nativeUnsafe,RustFlat,RustFlat32idx,RustRows,
   Java,JavaDouble,JavaVector,JavaXint,Tcl,TclBraced,TclLists,Julia,
   JuliaO0,JuliaO1,JuliaO2,JuliaO3,JuliaInt32,JuliaNB,JuliaMain32,JuliaF64,
   Javascript,JavascriptNoopt,JavascriptBaseline,JavascriptInterp,JavascriptRows,
   JavascriptBun,JavascriptRowsBun,JavascriptDeno,JavascriptRowsDeno,RubyRaw26,
   RubyWhile26,RubyRaw33,RubyWhile33,RubyRaw33YJIT,RubyWhile33YJIT,RubyNumo,
   RubyNumo2,RubyNumo2F32,RubyNumoF32,RubyNumoYJIT,RubyNumo2YJIT,Go,GoNoBCE,
   GoRange,GoRange32,LuaJIT,LuaFFI,LuaFFIF32,LuaJITFloat,CSharp,CSharpF32,
   CSharpSIMD,Crystal,Crystal32,CrystalPtr,OCaml,OCamlUnroll,OCamlBigarray32,
   OCamlMapi,PyPy,PyPyFloatLists,PyPyRows,Zig,Zig32,ZigFor,SBCLUntyped,
   SBCLTyped,SBCLFlat,SBCLFlat32,SBCLTyped32,Haskell,HaskellPtr,HaskellPtr32,
   HaskellArr,Haskell32,FSharp,FSharpWhile,FSharpF32,FSharpF32While,CSharpAOT,
   CSharpF32AOT,CSharpAOTSpeed,DLang,DLang32,DLangNative,Nim,NimRowsPtr,
   NimRowsPtr32,NimFlat,NimFlat32,Nim32,NimNative,KotlinJVM,KotlinF32,
   PyPyNumpy,OctaveLoop,OctaveLoopC,OctaveVec,OctaveVecS,J,JFloat,JFloatIdx,
   JLoop,AplLoop,AplRow,AplArray,AplRank,SwiftFlatO,SwiftFlatOunchecked,
   DartJIT,DartFlatJIT,DartF32JIT,DartAOT,DartFlatAOT,DartF32AOT,PHP,
   PHPRows,PHPJIT,PHPRowsJIT,PHPJITfunc,ChezScheme,ChezSchemeO3,ChezNoTrap,
   ChezBV32,Mawk,MawkFlat,Gawk,GawkFlat,GawkAoA,Bash,BashArith,AdaO3,
   AdaO3gnatp,AdaRngO3,AdaRngO3gnatp,AdaRng32O3,AdaRng32O3gnatp,Ada32gnatp,
   AdaNative,RawCdclangO3,RawCdclangO3native,RawCdsingleO3,FortranArray,
   FortranCol,FortranDoConc,FortranDouble,JuliaBcast,JuliaBcastO3,JuliaBcast32,
   JavascriptFlat,JavascriptTyped,JavascriptFlat32,JavascriptFlat32R,JavascriptFlatBun,
   JavascriptTypedBun,JavascriptFlat32Bun,JavascriptFlat32RBun,JavascriptFlatDeno,
   JavascriptTypedDeno,JavascriptFlat32Deno,SwiftGridO,SwiftGridOunchecked,
   SwiftFlat32O,SwiftFlat32Ounchecked,SwiftBufO,SwiftBufOunchecked,SwiftRowsO,
   SwiftRowsOunchecked,RawCclang,RawCclangO,RawCclangO1,RawCclangO2,RawCclangO3,
   RawCclangO3native,RawCgcc,RawCgccO,RawCgccO1,RawCgccO2,RawCgccO3,RawCgccO3native,
   RawCsingleO3,RawCrestrictO3native,RawCvlaO3,RawCvlaGcc15O3native,RawCgcc15O3native,
   VecCclang,VecCclangO,VecCclangO1,VecCclangO2,VecCclangO3,VecCclangO3native,
   VecCgcc,VecCgccO,VecCgccO1,VecCgccO2,VecCgccO3,VecCgccO3native,BoostCclang,
   BoostCclangO,BoostCclangO1,BoostCclangO2,BoostCclangO3,BoostCclangO3native,
   BoostCgcc,BoostCgccO,BoostCgccO1,BoostCgccO2,BoostCgccO3,BoostCgccO3native,
   BoostCclangNoAssert,BoostCclangONoAssert,BoostCclangO1NoAssert,BoostCclangO2NoAssert,
   BoostCclangO3NoAssert,BoostCclangO3nativeNoAssert,BoostCgccNoAssert,BoostCgccONoAssert,
   BoostCgccO1NoAssert,BoostCgccO2NoAssert,BoostCgccO3NoAssert,BoostCgccO3nativeNoAssert,
   BoostCgcc15O3nativeNoAssert,BoostCintO3NoAssert,BoostCdataO3native,CppMdspanO3,
   CNumRclang,CNumRclangO,CNumRclangO1,CNumRclangO2,CNumRclangO3,CNumRclangO3native,
   CNumRgcc,CNumRgccO,CNumRgccO1,CNumRgccO2,CNumRgccO3,CNumRgccO3native,
   CNumRgcc15O3native]

# ------------------------------------------------------------------------------
#
#                          M a i n   P r o g r a m

#  First, list the versions of all the compilers, interpreters, etc. that
#  are being used.

print ("")
print ("Versions:")
print ("")
ListVersion("Clang    ","c++ --version")
ListVersion("Assembler","c++ --version")
ListVersion("Gcc      ","g++ --version")
ListVersion("Gfortran ","gfortran --version")
ListVersion("R        ","Rscript --version")
ListVersion("Python2  ","python --version")
ListVersion("Python3  ","python3 --version")
ListVersion("Java     ","java -version")
ListVersion("Node.js  ","node --version")
ListVersion("Bun      ","bun --version")
ListVersion("Deno     ","deno --version")
ListVersion("Ruby     ","ruby --version")
ListVersion("Go       ","go version")
ListVersion("LuaJIT   ","luajit -v")
ListVersion("C#/.NET  ","dotnet --version")
ListVersion("Crystal  ","crystal --version")
ListVersion("OCaml    ","ocamlopt --version")
ListVersion("PyPy     ","pypy3 --version")
ListVersion("Zig      ","zig version")
ListVersion("SBCL     ","sbcl --version")
ListVersion("GHC      ","ghc --version")
ListVersion("D (LDC)  ","ldc2 --version")
ListVersion("Nim      ","nim --version")
ListVersion("Octave   ", "octave-cli --version")
ListVersion("Kotlin   ","kotlinc -version")
ListVersion("J        ","jconsole verJ.ijs")
ListVersion("Tcl      ","tclsh ver.tcl")
ListVersion("Swift    ","xcrun swiftc --version")
ListVersion("Julia    ","julia --version")
ListVersion("Rust     ","rustc --version")
ListVersion("Perl/PDL ","pdl -V")
ListVersion("Codon    ","codon --version")
ListVersion("Cython   ","pyext-python -m cython --version")
ListVersion("Pythran  ","pyext-python -m pythran.run --version")
ListVersion("Mojo     ","mojo --version")
ListVersion("Raku     ","raku --version")
ListVersion("GDL      ","gdl-run --version")
ListVersion("Clojure  ","clojure --version")
ListVersion("Elixir   ","elixir --version")
ListVersion("Chapel   ","chpl --version")
ListVersion("Lua      ","lua -v")
ListVersion("GraalPy  ","graalpy --version")
ListVersion("TruffleRb","truffleruby --version")
ListVersion("wasmtime ","wasmtime --version")
ListVersion("APL      ","dyalogscript verAPL.apls")
ListVersion("Dart     ","dart --version")
ListVersion("PHP      ","php -v")
ListVersion("Chez     ","chez --version")
ListVersion("mawk     ","mawk -W version")
ListVersion("gawk     ","gawk --version")
ListVersion("bash     ","/opt/homebrew/bin/bash --version")
ListVersion("GNAT     ","gnatmake --version")
#  MATLAB's version is not listed here: starting it costs ~13 s. It is
#  whichever /Applications/MATLAB_R*.app bin/matlab-run picks (R2026b).


#  Set the size of the array to be used for the test. There isn't much of a
#  good reason for using 10 rows of 2000 elements, but the repeat counts
#  in the tests were set up assuming that, so making the array much bigger
#  will increase the time taken unless the repeat counts are adjusted.
#  Note that 2000 is not a multiple of 16 or any higher power of 2, and some
#  highly optimised implementations using vector operations may run faster
#  if given a size that is a multiple of the largest vector the CPU can
#  handle. But using 2000 makes that a bit harder for them, which may be no
#  bad thing. Also set the number of times the full set of tests is to be
#  repeated - if the test set is repeated, the lowest measured time for any
#  individual test is used.

Nx = 2000
Ny = 10
Ntests = 1

if (len(sys.argv) > 1):
   Ntests = int(sys.argv[1])
   if (len(sys.argv) > 2):
      Nx = int(sys.argv[2])
      if (len(sys.argv) > 3):
         Ny = int(sys.argv[3])

#  Build up a list of all the different language/techniques we have.
#  Ditto a list of all the compilers/option combinations we have.

LangTechList = []
CompOptList = []
for Test in FullTests :
   LangTech = Test[0]
   CompOpt = Test[1]
   if (not LangTech in LangTechList) : LangTechList.append(LangTech)
   if (not CompOpt in CompOptList) : CompOptList.append(CompOpt)
LangTechList = sorted(LangTechList,key = lambda s : s.lower())
CompOptList = sorted(CompOptList,key = lambda s : s.lower())
NLangTech = len(LangTechList)
NCompOpt = len(CompOptList)

#  Now, set up a 2D array NLangTech by NCompOpt which will contain the matrix
#  of relative times for each test. Most of the elements will be null (we use
#  zero), since most Language/Compiler combinations just don't work. But this
#  is a good way to lay out the results, and can form the basis of the
#  spreadsheet data this program will create.

Results = numpy.zeros((NLangTech,NCompOpt))

#  We can run the full set of tests a number of times, to try to even out
#  any variations.

for ITest in range(Ntests) :

   print ("")
   if (Ntests > 1) :
      print ("Starting pass",ITest + 1,"of",Ntests,"through full set of tests")
   else :
      print ("Running through full set of timing tests")
   print ("")
   print ("Arrays used:",Nx,"columns,",Ny,"rows")
   print ("")

   #  Run each test in turn. That's really all we do.

   for Test in FullTests :

      #  Test[0] is language/technique, Test[1] the compiler/interpreter & flags.
      #  Test[2] and Test[3] are the build commands, Test[4] is the command
      #  to run the test, Test[5] is the number of iterations, and Test[6] is
      #  the cleanup command.
      
      LangTech = Test[0]
      CompOpt = Test[1]
      Nrpt = Test[5]
      (Status,Secs,Errors) = \
         BuildAndTimeProgram(Test[2],Test[3],Test[4],Nrpt,Nx,Ny,Test[6])
      if (Status) :
         print (LangTech,CompOpt,"Error:",Status,Errors)
      else :
         KIterSecs = (Secs / float(Nrpt)) * 1000.0
         print ("%24s %20s Rept: %8d Elap: %10.2f 1K Iter: %10.2g" %
                                   (LangTech,CompOpt,Nrpt,Secs,KIterSecs))

         #  Record the result (the time to perform 1000 iterations) in the
         #  Results array, using the indices for the language and compiler used.
         #  If we are running more than one iteration of the full test loop,
         #  we take the lowest (non-zero) number we get from any one iteration.

         LangTechIndex = LangTechList.index(LangTech)
         CompOptIndex = CompOptList.index(CompOpt)
         if (KIterSecs > 0.0) :
            LowestSoFar = Results[LangTechIndex,CompOptIndex]
            if (LowestSoFar <= 0.0) :
               Results[LangTechIndex,CompOptIndex] = KIterSecs
            else :
               if (KIterSecs < LowestSoFar) :
                  Results[LangTechIndex,CompOptIndex] = KIterSecs

#  Find the benchmark result - the lowest number in the results table (ignoring
#  the zeros from non-existent or failed tests)

First = True
FastestLangTech = ""
FastestCompOpt = ""
BenchKIterSecs = 1.0
for LangTechIndex in range(NLangTech) :
   for CompOptIndex in range(NCompOpt) :
      Result = Results[LangTechIndex,CompOptIndex]
      FastestSoFar = False
      if (Result > 0.0) :
         if (First) :
            FastestSoFar = True
            First = False
         else :
            if (Result < BenchKIterSecs) : FastestSoFar = True
      if (FastestSoFar) :
         BenchKIterSecs = Result
         FastestLangTech = LangTechList[LangTechIndex]
         FastestCompOpt = CompOptList[CompOptIndex]
print ("Fastest combination is ",FastestLangTech,"and",FastestCompOpt)

#  (2026) Relative times are given against Keith's arm64 assembler, the
#  study's reference, rather than against whichever test was fastest: some
#  2026 float32 variants run faster than the assembler.

if ("Assembler" in LangTechList and "clang (arm64)" in CompOptList) :
   RefResult = Results[LangTechList.index("Assembler"),CompOptList.index("clang (arm64)")]
   if (RefResult > 0.0) :
      BenchKIterSecs = RefResult
      print ("Relative times are against  Assembler and clang (arm64)")

#  Now that we know the benchmark speed, output a final list of results, this
#  time including the relative speed for each test.

print ("")
print ("Summary of relative speeds:")
print ("")
for Test in FullTests :
   LangTech = Test[0]
   CompOpt = Test[1]
   LangTechIndex = LangTechList.index(LangTech)
   CompOptIndex = CompOptList.index(CompOpt)
   KIterSecs = Results[LangTechIndex,CompOptIndex]
   RelativeSpeed = KIterSecs / BenchKIterSecs
   print ("%24s %20s 1K Iter: %10.2g, Relative time %12.2f" %
                                (LangTech,CompOpt,KIterSecs,RelativeSpeed))

#  Finally, output the summary table of relative speeds in a .csv format that
#  can be read by most spreadsheet programs.

print ("")
Line = "Compiler"
for LangTech in LangTechList :
   Line = Line + ',' + LangTech
print (Line)
for CompOpt in CompOptList :
   CompOptIndex = CompOptList.index(CompOpt)
   Line = CompOpt
   for LangTechIndex in range(NLangTech) :
      Result = Results[LangTechIndex,CompOptIndex] / BenchKIterSecs
      ResultString = ""
      if (Result > 0.0) : ResultString = ("%.2f" % Result)
      Line = Line + ',' + ResultString
   print (Line)




