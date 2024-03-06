//---------------------------------------------------------------------- 
// Copyright 2011-2018 Cadence Design Systems, Inc.
// Copyright 2010-2011 Mentor Graphics Corporation
// Copyright 2017 NVIDIA Corporation
// Copyright 2010-2011 Synopsys, Inc.
//   All Rights Reserved Worldwide 
// 
//   Licensed under the Apache License, Version 2.0 (the 
//   "License"); you may not use this file except in 
//   compliance with the License.  You may obtain a copy of 
//   the License at 
// 
//       http://www.apache.org/licenses/LICENSE-2.0 
// 
//   Unless required by applicable law or agreed to in 
//   writing, software distributed under the License is 
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
//   CONDITIONS OF ANY KIND, either express or implied.  See 
//   the License for the specific language governing 
//   permissions and limitations under the License. 
//----------------------------------------------------------------------


program top;

`include "uvm_macros.svh"
import uvm_pkg::*;

class test extends uvm_component;
  `uvm_component_utils(test)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    `uvm_info("PASS", "** UVM TEST PASSED **", UVM_NONE)
  endfunction : final_phase
endclass : test  
  
  // Need to extend root so it can be arbitrarily instanced
class my_root extends uvm_root;
  function new();
    super.new();
  endfunction : new

endclass : my_root

  // this coreservice type initializes everything inside of
  // its constructor (instead of deferring to the get() calls)
class my_coreservice_t extends uvm_default_coreservice_t;
  // Variables for storing the core types
  uvm_root r_inst;
  uvm_factory f_inst;
  uvm_report_server rs_inst;
  uvm_tr_database trdb_inst;
  uvm_visitor#(uvm_component) vis_inst;
  uvm_printer prt_inst;
  uvm_packer pkr_inst;
  uvm_comparer cmp_inst;
  uvm_copier cpy_inst;
  uvm_resource_pool rp_inst;

  function new();
    my_root r;
    super.new();

    begin my_root r =new(); r_inst =r; end
    begin uvm_default_factory r = new(); f_inst=r; end
    begin uvm_default_report_server r = new(); rs_inst = r; end
    begin uvm_text_tr_database r = new(); trdb_inst=r; end
    begin uvm_component_name_check_visitor r = new(); vis_inst=r; end
    begin uvm_table_printer r =new(); prt_inst =r; end
    pkr_inst = new();
    cmp_inst = new();
    cpy_inst = new();
    rp_inst = new();
  endfunction : new

  virtual  function uvm_root get_root();
    return r_inst;
  endfunction : get_root

  virtual  function uvm_factory get_factory();
    return f_inst;
  endfunction : get_factory

  virtual  function uvm_report_server get_report_server();
    return rs_inst;
  endfunction : get_report_server

  virtual  function uvm_tr_database get_default_tr_database();
    return trdb_inst;
  endfunction : get_default_tr_database

  virtual  function uvm_visitor#(uvm_component) get_component_visitor();
    return vis_inst;
  endfunction : get_component_visitor
  
  virtual  function uvm_printer get_default_printer();
    return prt_inst;
  endfunction : get_default_printer

  virtual  function uvm_packer get_default_packer();
    return pkr_inst;
  endfunction : get_default_packer

  virtual  function uvm_comparer get_default_comparer();
    return cmp_inst;
  endfunction : get_default_comparer

  virtual  function uvm_copier get_default_copier();
    return cpy_inst;
  endfunction : get_default_copier

  virtual  function uvm_resource_pool get_resource_pool();
    return rp_inst;
  endfunction : get_resource_pool
  
endclass : my_coreservice_t


  // The coreservice is instanced during static init, but
  // uvm_init isn't called until later.
  my_coreservice_t my_cs = new();

initial
  begin
    // if any of the creations in my_coreservice_t resulted in
    // a uvm_coreservice_t::get() call, then the next uvm_init
    // will be ignored.  As such, the if statement would fail
    // the test.
    uvm_init(my_cs);
    if (uvm_coreservice_t::get() != my_cs)
      `uvm_fatal("FAIL", "Not the right core service!")

    run_test();

  end

endprogram
