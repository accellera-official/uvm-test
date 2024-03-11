module test();
  import uvm_pkg::*;
  
  `include "uvm_macros.svh"

  function bit check(string src, dest[$]);
    string tmp[$];
    uvm_string_split(src, ",", tmp);
    if (tmp != dest) begin
      `uvm_error("FAIL", $sformatf("'%s' yielded '%p', but expected '%p'",
                                   src,
                                   tmp,
                                   dest))
      return 0;
    end
    else begin
      `uvm_info("GOOD", $sformatf("'%s' successfully produced '%p'",
                                  src,
                                  dest), UVM_NONE)
      return 1;
    end
  endfunction : check  
  
  initial begin
    bit pass;
    $display("** UVM TEST EXPECT NO SUMMARY **");
    pass = 1;
    pass &= check(",", '{"",""});
    pass &= check("1,,2", '{"1","","2"});
    pass &= check("", '{""});
    pass &= check(",foo,,", '{"","foo","",""});
    if (!pass)
      $display("** UVM TEST FAILED **");
    else
      $display("** UVM TEST PASSED **");
  end // initial begin

endmodule // test

