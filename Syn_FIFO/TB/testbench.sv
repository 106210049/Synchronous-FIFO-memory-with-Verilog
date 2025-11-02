`include "interface.sv"
`include "test.sv"
module tb_top;

  // Clock & reset
  bit clk;
  bit rst_n;

  // Tham số DUT
  localparam DATASIZE  = 8;
  localparam DEPTH     = 16;
  localparam PTR_WIDTH = $clog2(DEPTH);

  // Clock generator
  initial clk = 0;
  always #2 clk = ~clk;

  // Interface instance
  fifo_if vif(clk, rst_n);

  // DUT instance
  Synchronous_FIFO_memory #(DATASIZE, DEPTH, PTR_WIDTH) dut (
    .clk(vif.clk),
    .rst_n(vif.rst_n),
    .w_en(vif.w_en),
    .r_en(vif.r_en),
    .data_in(vif.data_in),
    .data_out(vif.data_out),
    .fifo_full(vif.fifo_full),
    .fifo_empty(vif.fifo_empty),
    .fifo_overflow_flag(vif.fifo_overflow_flag),   // optional
    .fifo_underflow_flag(vif.fifo_underflow_flag)   // optional
  );

  // Test / Environment
  test t1(vif);

  // Reset sequence
  initial begin
    clk = 0;
    rst_n = 0;
    #5 rst_n = 1;

  end

  // Waveform dump
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1);
  end

endmodule
