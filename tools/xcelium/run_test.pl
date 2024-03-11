##---------------------------------------------------------------------- 
## Copyright 2017-2018 Cadence Design Systems, Inc.
## Copyright 2010 Synopsys, Inc.
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
use Cwd 'realpath';
use Data::Dumper;

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
sub run_the_test {
  local($testdir, $xcelium_comp_opts, $xcelium_sim_opts, $compat_opts, $_) = @_;

	$xcelium = "xrun -clean $xcelium_comp_opts -uvmhome $uvm_home -nocopyright $compat_opts test.sv +UVM_TESTNAME=test $xcelium_sim_opts -uvmnocdnsextra -access rw";
	#        $xcelium .= " -nostdout" unless $opt_v;

  print "$xcelium\n" if $opt_v;
  return system("cd $testdir; $xcelium");
}

#
# Return the name of the compile-time logfile
#
sub comptime_log_fname {
   return runtime_log_fname();
}


#
# Return the name of the run-time logfile
#
sub runtime_log_fname {
   return "xrun.log";
}


#
# Return a list of filename & line numbers with compile-time errors
# for the test in the specified directory as an array, where each element
# is of the format "fname#lineno"
#
# e.g. ("test.sv#25" "test.sv#30")
#
sub get_compiletime_errors {
  local($testdir) = @_;

  local($log)= "$testdir/" . comptime_log_fname();

  open(LOG,$log) or die("couldnt open log [$log] [$!]");

  local(@errs)=();
  
  while ($_ = <LOG>) {
    if (/^(xmvlog|xmelab|irun): \*[EF],\w+ \(([^,]+),(\d+)\|(\d+)\):/,){ 
	  push(@errs, "$2#$3");
    }
  }

  close(LOG);

#  print join(":",@errs),"\n";

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
sub get_runtime_errors {
    local($testdir) = @_;
    local($log) = &realpath("$testdir/" . runtime_log_fname());

  open(LOG, $log) or die("couldnt open [$log] [$!]");

  local(@errs)=();

  while (<LOG>) {
   if (/^(xmsim): \*[FE],\w+ \(([^,]+),(\d+)\|(\d+)\):/) {
	  push(@errs, "$2#$3");
   } elsif (/^(\S+): \*[FE],\w+:/) {
	  push(@errs, "$2#0");
   }

    if (/^ERROR:/) {
	  push(@errs, "fname#2");
    }
  }

  close(LOG);
#  print join(":",@errs),"\n";

  return @errs;
}


#
# Clean-up all files created by the simulation,
# except the log files
#
sub cleanup_test {
  local($testdir, $_) = @_;

  system("cd $testdir; rm -rf xcelium.d waves.shm");
}

1;
