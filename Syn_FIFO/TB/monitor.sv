class monitor;
  mailbox mon_to_sb = new();
  virtual fifo_if vif;    
  transaction mon_tr;

  function new(mailbox mon_to_sb, virtual fifo_if vif);
    this.mon_to_sb = mon_to_sb;
    this.vif = vif;
  endfunction

  task run;
    wait(vif.rst_n == 1);  // chờ DUT thoát reset
    forever begin
      @(posedge vif.clk);
      
      // --- Ghi nhận khi có hoạt động ghi ---
      if (vif.w_en && !vif.fifo_full) begin
        mon_tr = new();
        mon_tr.tr_type = "WRITE";
        mon_tr.data_in = vif.data_in;
        mon_tr.fifo_full = vif.fifo_full;
        mon_tr.fifo_empty = vif.fifo_empty;
        mon_to_sb.put(mon_tr);
        $display("[MON] WRITE captured: data_in = %0d", vif.data_in);
      end

      // --- Ghi nhận khi có hoạt động đọc ---
      if (vif.r_en && !vif.fifo_empty) begin
      @(posedge vif.clk);  // chờ dữ liệu valid
        mon_tr = new();
        mon_tr.tr_type = "READ";
        mon_tr.data_out = vif.data_out;
	mon_tr.fifo_full = vif.fifo_full;
        mon_tr.fifo_empty = vif.fifo_empty;
        mon_to_sb.put(mon_tr);
        $display("[MON] READ captured: data_out = %0d", vif.data_out);
 	 end
    end
  endtask
endclass
