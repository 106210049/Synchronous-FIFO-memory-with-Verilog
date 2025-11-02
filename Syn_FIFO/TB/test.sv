`include "package.sv"
import fifo_pkg::*;
program test(fifo_if vif);
  env env_o;
  
  initial begin
    env_o = new(vif);
    env_o.agt.gen.count = 30;
    env_o.run();
  end
endprogram
