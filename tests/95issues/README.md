This directory is provided as a base for any tests used to verify issues posted on the GitHub [Issue Tracker](https://github.com/accellera-official/uvm-core/issues).

Please create a directory for each issue, starting with the issue ## and using a short unique identifier.  For example, [accellera-official#6](https://github.com/accellera-official/uvm-core/issues/6) would be in `${UVM_TESTS}/tests/95issues/06static_races/`.

**Note:** A directory name MUST start with 2 or more numerals for the run_test script to see it, a directory name of `6static_races` would note be seen.

If multiple tests are required for a single issue, then each test should be in a separate `##test_name` directory below the `##short_uid` directory.  E.g. `${UVM_TESTS}/tests/95issues/06static_races/00test_foo`
