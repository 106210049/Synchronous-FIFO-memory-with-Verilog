class driver;
  virtual fifo_if vif;
  mailbox gen_to_drv = new();
  transaction tr;
  
  function new(mailbox gen_to_drv, virtual fifo_if vif);
    this.gen_to_drv = gen_to_drv;
    this.vif = vif;
  endfunction
  
  task run;
    wait(vif.rst_n == 1);  // Đảm bảo DUT thoát reset
    forever begin
      gen_to_drv.get(tr);   // Nhận transaction từ generator
      
      // Chờ cạnh clock để gán dữ liệu vào DUT
      @(posedge vif.clk);
      
      vif.w_en = tr.w_en;
      vif.r_en = tr.r_en;
      
      if (!vif.fifo_full && tr.w_en) begin
        vif.data_in = tr.data_in;   // Gán dữ liệu ngay
      end
      
      if (!vif.fifo_empty && tr.r_en) begin
        @(posedge vif.clk);       // chờ dữ liệu valid
        vif.r_en <= 1;
	tr.data_out = vif.data_out;
	vif.r_en <= 0;
    end
    end
  endtask
endclass
