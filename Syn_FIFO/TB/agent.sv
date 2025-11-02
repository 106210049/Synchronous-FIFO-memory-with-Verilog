class agent;
  driver drv;
  monitor mon;
  generator gen;
  
  mailbox gen_to_drv;
  virtual fifo_if vif;
  
  function new(virtual fifo_if vif, mailbox mon_to_sb);
    gen_to_drv = new();
    
    drv = new(gen_to_drv, vif);
    mon = new(mon_to_sb, vif);
    gen = new(gen_to_drv);
  endfunction
  
  task run();
    fork 
      drv.run();
      mon.run();
      gen.run();
    join_any
  endtask
endclass