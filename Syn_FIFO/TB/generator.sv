class generator;
  int count;
  mailbox gen_to_drv = new();
  transaction tr;
  
  function new(mailbox gen_to_drv);
    this.gen_to_drv = gen_to_drv;
  endfunction

  task run;
    repeat(count) begin
      tr = new();
      void'(tr.randomize() with { 
            w_en dist {1:=60, 0:=40};
            r_en dist {1:=40, 0:=60};
            data_in inside {[0:255]};
      });
      gen_to_drv.put(tr);
    end
  endtask
endclass
