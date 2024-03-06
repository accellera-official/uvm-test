# Accellera Universal Verification Methodology Tests

# Scope

This repository is provided as means of contributing tests for the verification of UVM errata, as described by [uvm-core/DEVELOPMENT.md](https://github.com/accellera-official/uvm-core/blob/main/DEVELOPMENT.md).


# License

This repository is licensed under the Apache-2.0 license.  The full text of
the Apache license is provided in this kit in the file [LICENSE.txt](./LICENSE.txt).

# Copyright

All copyright owners for this kit are listed in [NOTICE.txt](./NOTICE.txt).

All Rights Reserved Worldwide

# Contacts and Support

If you have questions about this repository and/or its application, please visit the
[Accellera UVM (IEEE 1800.2) - Methodology and BCL Forum](https://forums.accellera.org/forum/43-uvm-ieee-18002-methodology-and-bcl-forum/) or 
contact the Accellera UVM Working Group (uvm-wg@lists.accellera.org).

# Git details

The following information may be used for tracking the version of this file.  Please see
[DEVELOPMENT.md](./DEVELOPMENT.md) for more details.

```
$File$
$Rev$
$Hash$
```

# Usage

## Recommendations

Please follow the following recommendations when you create tests 
so that they easily work across all tool chains, with changing versions of UVM, ..

- prefer test.sv based tests over test.pl or makefile based tests

- prefer self checking tests over gold file based tests

- only have ONE test per test directory. 

- Avoid tests which run in a directory other than the current test directory

- avoid copying post_test.pl to the test run directory and make a link instead

- prefer `uvm_report_catcher` to `UVM TEST EXPECT ...` report checking.

## Prerequisites

- The runner is a perl based script so it requires a 5.8+ perl.

- The runner requires a backend for the choosen tool chain.

- The runner may utilize make in order to start makefile based tests

- The runner needs a uvm-core library installation and a set of tests, a test hierarchy or a file pointing to tests.

- test.sv based tests pass a `+UVM_TESTNAME=test` to the test and therefore require that there is a test named "test" deriving from "uvm_test".

## Document terminology

The following syntax is used throughout the document 

- `${UVM_CORE}` is the absolute path to the uvm installation.

- `${UVM_TESTS}` is the location of the uvm tests installation

- `${TOOL}` refers to the tool chain. currently the supported tool chains are `clean|echo|ius|questa|vcs|vcsi|xcelium`

**Note:** These are _not_ environment variables, they exist as a shorthand for the documentation.

## Locations

The test runner is located here `${UVM_TESTS}/admin/bin/run_tests` while the tool chain 
support scripts are stored in `${UVM_TESTS}/tools/${TOOL}/run_tests.pl`

## Simple Usage

The minimal arguments are the location of the uvm installation, the tool chain to use and at least one test.

```
cd ${UVM_TESTS} && admin/bin/run_tests -u ${UVM_CORE} ${TOOL} tests
```

**Note:** `admin/bin/run_tests -h` provides a complete breakdown of the supported arguments.


## Test selection

Tests are directories supplied on the command line or via a file using the `-f` option of 
the runner. Each directory is considered a test and the runner will launch a simulation 
within that directory given that one of the following applies:

1. a file `test.sv` is present or
2. a file `test.pl` is present 

in that directory.

Subdirectories of the supplied tests are scanned recursively and added to the test set ONLY 
if they match the `^[0-9][0-9]` file name pattern.


## Referencing the UVM install from scripts/tests

Processes forked from the test runner will have the env variable `UVM_HOME` set pointing to 
the UVM installation being used.

## Execution flow for a single test

The test runner executes the test unless a file `all.skip` or `${TOOL}.skip` is present in the test directory. 
The skip will be reported. Then the test is executed through the following methods.

### Flow for a test.sv based test

1. The test is compiled and run. This step utilizes the contents of the following files
	- ${TOOL}.comp.args
	- test.defines
	- ${TOOL}.run.args
	- test.plusargs
	
Its is upto the tool chain to use these arguments and perform the steps in a single 
step or using multiple steps.

2. the test is checked. see [Determining test status](#determining-test-status)

3. cleanup is performed: In this step the tool chain removes all created files. It is upto 
   the tool chain to define the set of files to remove.

### Flow for a test.pl based test

In this flow the runner executes the provided test.pl and uses the return status as test execution 
status. It is upto the user to perform compile+run as necessary.

## Determining test status

Test status is determined differently for `test.sv` tests vs. `test.pl` tests.  Additionally, test status may be affected by the presence of a `post_test.pl` script.

### Determining test status in test.sv mode

1. if no compile log is present the test is considered fail

2. if compile errors are present the test fails unless they are expected. 
   If a compile time error is expected the log or error message must provide the "UVM TEST COMPILE-TIME FAILURE" as part of the log.

3. if the test directory contains a post_test.pl file it will be executed to determine pass/fail alone. The builtin 
   pass failure algorithm in the next step is NOT applied.

4. The log is scanned for the following patterns

 - The presence of `UVM TEST FAILED`  makes the test fail
 - The absence of `UVM TEST PASS` makes the test fail
 - The absence of `UVM Report Summary` without a corresponding `UVM TEST EXPECT NO SUMMARY` makes the test fail

  If `UVM Report Summary` is present in the log, then the number of `UVM_ERROR` and `UVM_FATAL` messages is checked.
 - By default, any number above zero makes the test fail.
 - A test can specify that it expects some number of these messages using `UVM TEST EXPECT \d+ UVM_ERROR` and `UVM TEST EXPECT \d+ UVM_FATAL`.  The test will fail if the number seen does not match the number of expected.
 
5. a `${TOOL}` runtime error leads to a failing simulation unless the log/message produces the magic pattern "UVM TEST RUN-TIME FAILURE" as part of the message or log.

### Running makefile based simulations through test.pl

The test.pl method can be used to start makefile based tests by using something like

```perl
return &make_example("${uvm_home}/examples/simple/registers/vertical_reuse");
```

This requires the `Makefile.${TOOL}` is present in the chosen directory.

### Gold file based tests using post_test.pl

The provided [post test script](admin/bin/post_test.pl) can be used to check gold file based tests. 
In order to utilize it you should make a link to the `post_test.pl` in the test directory pointing back to `admin/bin/post_test.pl`.

The script makes the following assumptions

1. gold files are stored in `*.au` or `*.au.${TOOL}` files
2. the filter will strip certain patterns from the gold and the logfile. this includes changing patterns or special `${TOOL}` specific information.
3. a gold file `<foo>` is compared to `<foo>.au` or `<foo>.au.${TOOL}`
4. if a gold file `<foo>.au` or `<foo>.au.${TOOL}` is present then the 
   file `<foo>` must also exist and there must be gold files for the other `${TOOL}`s too.

The combination of a logfile `<foo>` and gold file `<foo>.au` or `<foo>.au.${TOOL}` is first processed 
into a file `<foo>.post` and `<foo>.au.post` (or `<foo>.au.${TOOL}.post`). Once processed the two resulting files are diffed using the system "diff" 
command and the difference is stored in a `<foo>.df` file. The script reports an eventual difference between the post files as failure.

---------------------------------------------------------------------
## Writing a test.sv UVM test
---------------------------------------------------------------------

1. create a directory in the `${UVM_TESTS}/tests` hierarchy. The directory name must start with at least two digits to be recognised automatically.
2. create your test in `test.sv`
3. ensure the test class inherits from uvm_test and is named `test`
4. place additional switches and arguments in the menitoned configuration files
5. emit failures using the standard UVM `` `uvm_error`` and `` `uvm_fatal`` macros or the `uvm_report_error` and `uvm_report_fatal` functions. 
6. encode specific pass/fail logic in the `uvm_test::report` method

For example:

```SystemVerilog
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
## Known test runner limitations
---------------------------------------------------------------------

- pass/fail logic: in some situation multiple contradicting status information can be obtained from log or exit status 
(or other contributing places). As such, any fail status will cause the test to fail, regardless of the presence of a PASS token.
