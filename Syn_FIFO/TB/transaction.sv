class transaction;

  // Kiểu giao dịch: "WRITE" hoặc "READ"
  string tr_type;

  // Dữ liệu và tín hiệu FIFO
  randc bit [7:0] data_in;
  bit [7:0] data_out;
  bit fifo_full;
  bit fifo_empty;
  bit fifo_overflow_flag;
  bit fifo_underflow_flag;
  // Cờ điều khiển
  rand bit w_en;
  rand bit r_en;
  
  constraint c1 { !(w_en && r_en); }
endclass