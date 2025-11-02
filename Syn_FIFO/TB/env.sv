class env;
  agent agt;
  scoreboard sb;
  
  mailbox mon_to_sb;
  
  function new(virtual fifo_if vif);
    mon_to_sb = new();
    agt = new(vif, mon_to_sb);
    sb = new(mon_to_sb);
  endfunction
  	
  task run();
    fork
      agt.run();
      sb.run();
    join_any
    
    wait(agt.gen.count == sb.compare_cnt);
    $display("Accuracy = %0.2f%%", (real'(sb.acc) / real'(sb.compare_cnt)) * 100.0);
    $finish;
  endtask
endclass

      
    