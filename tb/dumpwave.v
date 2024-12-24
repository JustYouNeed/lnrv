  
    reg[8*300:1] testcase;
  integer dumpwave;

  initial begin
    $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");  
    if($value$plusargs("TEST_CASE=%s",testcase))begin
      $display("TEST_CASE=%s",testcase);
    end
  
  initial begin

    if($value$plusargs("TEST_CASE=%s",testcase))begin
      $display("TEST_CASE=%s",testcase);
    end
    
    if($value$plusargs("DUMPWAVE=%d",dumpwave)) begin
      if(dumpwave != 0) begin

	 `ifdef vcs
            $display("VCS used");
            $fsdbDumpfile("tb_top.fsdb");
            $fsdbDumpvars(0, tb_top, "+mda");
         `endif

	 `ifdef iverilog
            $display("iverlog used");
	    $dumpfile("tb_top.vcd");
            $dumpvars(0, tb_top);
         `endif
      end
    end
  end