# UVM test harness documentation
===========================================================
v0.1, * January 2017

*An HTML-rendered copy of this document can be found at:*
 <https://github.com/OSCI-WG/uvm-tests/blob/master/admin/docs/UVM_TEST-HARNESS.md>.


This document outlines the capabilities of the test runner used for UVM test development and 
illustrates how tests can utilize the capabilities of the runner. 

---------------------------------------------------------------------
# Recommendations
---------------------------------------------------------------------

Please follow the following recommendations when you create tests 
so that they easily work across all tool chains, with changing versions of UVM, ..

- prefer test.sv based tests over test.pl or makefile based tests

- prefer self checking tests over gold file based tests

- only have ONE test per test directory. 

- Avoid tests which run in a directory other than the current test directory

- avoid copying post_test.pl to the test run directory and make a link instead

- avoid marking tests explicitly with 'PASS' rather mark failing tests with 'FAIL'. 
  This avoids problem when multiple contradicting conditions such as PASS and FAIL 
  messages occur within a single test.

---------------------------------------------------------------------
# Prerequisites
---------------------------------------------------------------------

- The runner is a perl based script so it requires a 5.8+ perl.

- The runner requires a backend for the choosen tool chain.

- The runner may utilize make in order to start makefile based tests

- The runner needs a uvm-core library installation and a set of tests, a test hierarchy or a file pointing to tests.

- test.sv based tests pass a `+UVM_TESTNAME=test` to the test and therefore require that there is a test named "test" deriving from "uvm_test".

---------------------------------------------------------------------
# Document terminology
---------------------------------------------------------------------

The following syntax is used throughout the document 

- $UVM-CORE is the absolute path to the uvm installation.

- $UVM-TESTS is the location of the uvm tests installation

- $CHAIN refers to the tool chain. currently the supported tool chains are `ius|questa|vcs|vcsi`

These are not environment variables.

---------------------------------------------------------------------
# Simple Usage
---------------------------------------------------------------------

The minimal arguments are the location of the uvm installation, the tool chain to use and at least one test.

```
cd <uvm-tests> && admin/bin/run_tests -u <path to uvm> ius tests
```

---------------------------------------------------------------------
# Locations
---------------------------------------------------------------------

The test runner is located here `$UVM-TESTS/admin/bin/run_tests` while the tool chain 
support scripts are stored in `$UVM-TESTS/tools/$CHAIN/run_tests.pl`


---------------------------------------------------------------------
# Test selection
---------------------------------------------------------------------

Tests are directories supplied on the command line or via a file using the `-f` option of 
the runner. Each directory is considered a test and the runner will launch a simulation 
within that directory given that one of the following applies:

1. a file test.sv is present or
2. a file test.pl is present 

in that directory.

Subdirectories of the supplied tests are scanned recursively and added to the test set ONLY 
if they match the `^[0-9][0-9]` file name pattern.


---------------------------------------------------------------------
# Referencing the UVM install from scripts/tests
---------------------------------------------------------------------

Processes forked from the test runner will have the env variable UVM_HOME set pointing to 
the UVM installation being used.

---------------------------------------------------------------------
# Execution flow for a single test
---------------------------------------------------------------------

The test runner executes the test unless a file $CHAIN$.skip is present in the test directory. 
The skip will be reported. Then the test is executed through the following methods

##  Flow for a test.sv based test

1. The test is compiled and run. This step utilizes the contents of the following files
	- $CHAIN.comp.args
	- test.defines
	- $CHAIN.run.args
	- test.plusargs
	
Its is upto the tool chain to use these arguments and perform the steps in a single 
step or using multiple steps.

2. the test is checked. see <determining test pass/fail>

3. cleanup is performed: In this step the tool chain removes all created files. It is upto 
   the tool chain to define the set of files to remove.

## Flow for a test.pl based test

In this flow the runner executes the provided test.pl and uses the return status as test execution 
status. It is upto the user to perform compile+run as necessary.

---------------------------------------------------------------------
# Determining test pass/fail in test.sv mode
---------------------------------------------------------------------

1. if no compile log is present the test is considered fail

2. if compile errors are present the test fails unless they are expected. 
   If a compile time error is expected the log or error message must provide the "UVM TEST COMPILE-TIME FAILURE" as part of the log.

3. if the test directory contains a post_test.pl file it will be executed to determine pass/fail alone. The buildin 
   pass failure algorithm in the next step is NOT applied.

4. The log is scanned for the following patterns

 `UVM TEST FAILED`  makes the test fail unconditionally
 `UVM TEST PASS` makes the test pass unconditionally
 `UVM TEST EXPECT \d+ UVM_ERROR` the test expects n UVM_ERRORS. failing to produce the errors makes the test fail.
 `UVM Report Summary` missing this pattern (which is produced by UVM's summary report) makes the test fail.

5. a $CHAIN runtime error leads to a failing simulation unless the log/message produces the magic pattern "UVM TEST RUN-TIME FAILURE" as part of the message or log.

---------------------------------------------------------------------
# Running makefile based simulations through test.pl
---------------------------------------------------------------------

The test.pl method can be used to start makefile based tests by using something like

return &make_example("$uvm_home/examples/simple/registers/vertical_reuse");

This requires the Makefile.$CHAIN$ is present in the chosen directory.

---------------------------------------------------------------------
# Gold file based tests using post_test.pl
---------------------------------------------------------------------

The provided script <uvm_tests/admin/bin/post_test.pl> can be used to check gold file based tests. 
In order to utilize it you should make a link to the post_test.pl in the test directory pointing back to admin/bin/post_test.pl.

The script makes the following assumptions

1. gold files are stored in *.au or *.au.$CHAIN$ files
2. the filter will strip certain patterns from the gold and the logfile. this includes changing patterns or special $CHAIN$ specific information.
3. a gold file <foo> is compared to <foo>.au or <foo>.au.$CHAIN$
4. if a gold file <foo>.au or <foo>.au.$CHAIN$ is present then the 
   file <foo> must also exist and there must be gold files for the other $CHAIN$s too.

The combination of a logfile <foo> and gold file <foo>.au or <foo>.au.$CHAIN$ is first processed 
into a file <foo>.post and <foo>.au.post (or <foo>.au.$CHAIN.post). Once processed the two resulting files are diffed using the system "diff" 
command and the difference is stored in a <foo>.df file. The script reports an eventual difference between the post files as failure.

---------------------------------------------------------------------
# Writing a test.sv UVM test
---------------------------------------------------------------------

1. create a directory in the `$UVM-TESTS/tests` hierarchy. The directory name must start with at least two digits to be recognised automatically.
2. create your test in `test.sv`
3. ensure the test class inherits from uvm_test and is named "test"
4. place additional switches and arguments in the menitoned configuration files
5. emit failures using the standard UVM uvm_error and uvm_fatal macros or the uvm_report_error and uvm_report_fatal functions. 
6. encode specific pass/fail logic in the `uvm_test::report method`

?? i believe a test will pass if all required messages appear and no failure has been detected - verify ??


```
import uvm_pkg::*;
`include "uvm_macros.svh"


module top;
  initial 
    run_test();
  
endmodule

class test extends uvm_component;
  `uvm_component_utils(test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    // start your test
    
    phase.drop_objection(this);
 endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server rs = uvm_report_server::get_server();
  	  super.report_phase(phase);
    if(rs.get_severity_count(UVM_ERROR) > 0)
      $display("** UVM TEST FAIL **");
    else
      $display("** UVM TEST PASSED **");
  endfunction
endclass
```
---------------------------------------------------------------------
# Known test runner limitations
---------------------------------------------------------------------

- pass/fail logic: in some situation multiple contradicting status information can be obtained from log or exit status 
(or other contributing places). This may lead to incorrect pass/fail status. As a safe measure you should only make tests 
explicitly failed but never explicitly pass. 