##---------------------------------------------------------------------- 
## Copyright 2018 Cadence Design Systems, Inc.
## Copyright 2010-2014 Mentor Graphics Corporation
## Copyright 2010 AMD
## Copyright 2010-2011 Synopsys, Inc.
##   All Rights Reserved Worldwide 
## 
##   Licensed under the Apache License, Version 2.0 (the 
##   "License"); you may not use this file except in 
##   compliance with the License.  You may obtain a copy of 
##   the License at 
## 
##       http://www.apache.org/licenses/LICENSE-2.0 
## 
##   Unless required by applicable law or agreed to in 
##   writing, software distributed under the License is 
##   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
##   CONDITIONS OF ANY KIND, either express or implied.  See 
##   the License for the specific language governing 
##   permissions and limitations under the License. 
##----------------------------------------------------------------------


#
# Questa-Specific test running script
#


#
# Make sure the version of Questa can run these tests
#

sub questa_support($$$) {
    my ($series,$letter,$beta) = @_;
    if (!(($series eq "6.6" && $letter ge "d") || ($series > 6.6))) {
      print "Questa version \"$series$letter$beta\" does not fully support UVM.\n".
      "- required version 6.6d or later\n";
    }
    return 1;
}

sub questa_checkversion() {
    my $vlog_version = `vlog -version`;
    chomp $vlog_version;
    if ($vlog_version !~ m/((\d+\.\d+)([a-z])?)/) {
        die "Unable to get Questa version from 'vlog -version': $vlog_version\n";
    }
    my $version = $1;
    my ($series,$letter,$beta) = ($version =~ m/^(\d+\.\d+)([a-z])?\s*([Bb]eta\s+([0-9])?\d?)?$/i);
    die "Unrecognised Questa version number: \"$version\"\n" unless (defined $series);
    &questa_support($series,$letter,$beta);
    print "# Questa version $version ($vlog_version)\n" if ($opt_v);
}


#
# Standard way to run commands for debug
#

sub questa_run($) {
    my ($cmd) = @_;
    print STDOUT "# $cmd\n" if ($opt_v);
    system($cmd);
}


#
# Run the test implemented by the file named "test.sv" located
# in the specified directory, using the specified compile-time
# and run-time command-line options
#
# The specified directory must also be used as the CWD for the
# simulation run.
#
# Run silently, unless $opt_v is specified.
#
sub run_the_test($$$) {
    my ($testdir,$compile_opts,$run_opts,$compat_opts) = @_;
    &questa_checkversion();
    my $uvm_opts = "+incdir+$uvm_home/src $uvm_home/src/uvm.sv $compat_opts";

    # how to direct output - verbose/silent
    my $redirect = ($opt_v) ? "| tee -a" : ">>";

    # prepare by making sure log files and QA stamp are removed
    &questa_run("cd $testdir && rm -f qa ".&comptime_log_fname()." ".&runtime_log_fname());

    # compile commands
    # +acc=rb needed for DPI backdoor access
    my $QCFLAG = "-DQUESTA";
    my $vlog;
    if ($compile_opts !~ /UVM_NO_DPI/) {
      $vlog = ("vlog -writetoplevels work/top_levels -lint -suppress 2218,2181  $compile_opts $uvm_opts  $compat_opts -timescale 1ns/1ns test.sv -ccflags $QCFLAG -ccwarn off $uvm_home/src/dpi/uvm_dpi.cc");
    }
    else {
      $vlog = ("vlog -writetoplevels work/top_levels -lint -suppress 2218,2181 $compile_opts $uvm_opts $compat_opts -timescale 1ns/1ns  test.sv ");    
    }
    &questa_run("cd $testdir && ( $vlog ) $redirect ".&comptime_log_fname()." 2>&1");

    # only run if the compile succeeded in reaching QA
    if (-e "$testdir/work/top_levels") {
      my $vopt = ("vopt -quiet -f $testdir/work/top_levels -o opt -access=rw+/. -access=rw+uvm_polling_pkg -suppress 2108");      
      my $vsim = ("vsim opt -quiet -c +UVM_TESTNAME=test $run_opts -do 'run -all;quit -f' ");
      
      &questa_run("cd $testdir && $vopt");
      &questa_run("cd $testdir && $vsim $redirect ".&runtime_log_fname()." 2>&1");

    }
    return(0);
}


#
# Return the name of the compile-time logfile
#
sub comptime_log_fname() { return "compile.log"; }


#
# Return the name of the run-time logfile
#
sub runtime_log_fname() { return "run.log"; }


#
# Return a list of filename & line numbers with compile-time errors
# for the test in the specified directory as an array, where each element
# is of the format "fname#lineno"
#
# e.g. ("test.sv#25" "test.sv#30")
#
sub get_compiletime_errors($) {
    my ($testdir) = @_;
    my $log = "$testdir/".&comptime_log_fname();
    if (!open(LOG, "<$log")) { return (); }
    my @errs;
    while (my $line = <LOG>) {
        if ($line =~ m/^\#?\s*\**\s*Error:/) {
            if ($line =~ m/^\#?\s*\**\s*Error:\s*([^\(]+)\(([^\)]+)\):\s(.*)/) {
                my ($fname,$lineno,$err) = ($1,$2,$3);
                push(@errs, "$fname#$lineno");
            } else {
                print STDERR "\n# get_compiletime_error(): unknown error ($line)\n" if ($opt_v);
                push(@errs, "unknown#1");
            }
        }
    }
    close(LOG);
    return @errs;
}


#
# Return a list of filename & line numbers with run-time errors
# for the test in the specified directory as an array, where each element
# is of the format "fname#lineno"
#
# e.g. ("test.sv#25" "test.sv#30")
#
# Run-time errors here refers to errors identified and reported by the
# simulator, not UVM run-time reports.
#
sub get_runtime_errors($) {
    my ($testdir) = @_;
    my $log = "$testdir/".&runtime_log_fname();
    if (!open(LOG, "<$log")) { return (); }
    my @errs;
    while (my $line = <LOG>) {
        if ($line =~ m/^\#?\s*\**\s*Error:/) {
            # ** Error: test.sv(62): message
            if ($line =~ m/^\#?\s*\**\s*Error:\s*([^\(]+)\(([^\)]+)\):\s(.*)/) {
                my ($fname,$lineno,$err) = ($1,$2,$3);
                push(@errs, "$fname#$lineno");
            # ** Error: (vsim-XXXX) test.sv(62): message
            } elsif ($line =~ m/^\#?\s*\**\s*Error:\s*\(([^\)]+)\)\s*([^\(]+)\(([^\)]+)\):\s(.*)/) {
                my ($fname,$lineno,$err) = ($2,$3,$4);
                push(@errs, "$fname#$lineno");
            } elsif ($line =~ m/^\#?\s*\**\s*Error:\s*(.*) in file (.*) at line\s*([0-9]+)\./) {
                my ($fname,$lineno,$err) = ($2,$3,$1);
                push(@errs, "$fname#$lineno");
            } else {
                print STDERR "\n# get_runtime_error(): unknown error ($line)\n" if ($opt_v);
                push(@errs, "unknown#1");
            }
        }
    }
    close(LOG);
    return @errs;
}


#
# Clean-up all files created by the simulation,
# except the log files
#
sub cleanup_test($) {
  my ($testdir) = @_;
  system("cd $testdir && rm -rf qa work/ lib/ vsim.wlf debug.log");
}

1;
