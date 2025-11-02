class scoreboard;
  mailbox mon_to_sb = new();
  int compare_cnt;
  int acc;
  
  bit [7:0] ref_fifo[$];  // reference FIFO model (queue)

  function new(mailbox mon_to_sb);
    this.mon_to_sb = mon_to_sb;
    this.compare_cnt = 0;
  endfunction

  task run;
    forever begin
      transaction tr;
      mon_to_sb.get(tr);
      if (tr.tr_type == "WRITE") begin
        ref_fifo.push_back(tr.data_in);
        $display("[SB] WRITE logged: data_in = %0d", tr.data_in);
        acc++;
      end
      else if (tr.tr_type == "READ") begin
        if (ref_fifo.size() > 0) begin
          bit [7:0] expected = ref_fifo.pop_front();
          if (expected == tr.data_out)	begin
            $display("[SB] MATCH: expected=%0d, got=%0d ", expected, tr.data_out);
          	acc++;
          end
          else
            $display("[SB] MISMATCH: expected=%0d, got=%0d ", expected, tr.data_out);
        end
        else begin
          $display("[SB] UNDERFLOW DETECTED — no data in reference FIFO!");
        end
      end
      compare_cnt++;
    end
  endtask
endclass
