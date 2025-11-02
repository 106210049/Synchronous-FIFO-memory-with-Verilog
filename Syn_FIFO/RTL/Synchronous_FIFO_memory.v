`ifndef SYNTHESIS
    timeunit 1ps;
    timeprecision 1ps;
`endif

module Write_pointer #(
    parameter DATASIZE = 8, 
    parameter DEPTH = 16,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input  wire w_en,
    input  wire fifo_full,
    input  wire clk,
    input  wire rst_n,
    output wire fifo_w_en,
    output reg  [PTR_WIDTH:0] w_ptr  // include MSB for wrap detection
);
    assign fifo_w_en = (~fifo_full) & w_en;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) w_ptr <= 0;
        else if (fifo_w_en) w_ptr <= w_ptr + 1;
    end
endmodule

module Read_pointer #(
    parameter DATASIZE = 8, 
    parameter DEPTH = 16,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input  wire r_en,
    input  wire fifo_empty,
    input  wire clk,
    input  wire rst_n,
    output wire fifo_r_en,
    output reg  [PTR_WIDTH:0] r_ptr
);
    assign fifo_r_en = (~fifo_empty) & r_en;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) r_ptr <= 0;
        else if (fifo_r_en) r_ptr <= r_ptr + 1;
    end
endmodule

// MEMORY ARRAY: synchronous write, synchronous registered read (data_out registered)
module Memory_Array #(
    parameter DATASIZE = 8, 
    parameter DEPTH = 16,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input  wire                    clk,
    input  wire                    fifo_w_en,
    input  wire [PTR_WIDTH:0]      w_ptr,
    input  wire [PTR_WIDTH:0]      r_ptr,
    input  wire [DATASIZE-1:0]     data_in,
    input  wire                    fifo_r_en,
    output reg  [DATASIZE-1:0]     data_out
);
    reg [DATASIZE-1:0] mem [0:DEPTH-1];

    // write happens on posedge
    always @(posedge clk) begin
        if (fifo_w_en)
            mem[w_ptr[PTR_WIDTH-1:0]] <= data_in;
    end

    // registered read: capture output on posedge when fifo_r_en asserted
    always @(posedge clk) begin
        if (fifo_r_en)
            data_out <= mem[r_ptr[PTR_WIDTH-1:0]];
        // else keep previous data_out (classic synchronous FIFO behavior)
    end
endmodule

// MEMORY STATE: compute full/empty combinationally from pointers, but flags set/clear synchronously.
module Memory_State #(
    parameter DATASIZE = 8, 
    parameter DEPTH = 16,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   w_en,
    input  wire                   r_en,
    input  wire                   fifo_w_en,
    input  wire                   fifo_r_en,
    input  wire [PTR_WIDTH:0]     w_ptr,
    input  wire [PTR_WIDTH:0]     r_ptr,
    output reg                    fifo_full,
    output reg                    fifo_empty,
    output reg                    fifo_overflow_flag,
    output reg                    fifo_underflow_flag
);
    wire msb_diff = w_ptr[PTR_WIDTH] ^ r_ptr[PTR_WIDTH];
    wire lsb_equal = (w_ptr[PTR_WIDTH-1:0] == r_ptr[PTR_WIDTH-1:0]);

    // combinational full/empty from pointers (classic approach)
    always @(*) begin
        fifo_full  = msb_diff & lsb_equal;
        fifo_empty = (~msb_diff) & lsb_equal;
    end

    wire write_attempt_when_full = fifo_full  & w_en;
    wire read_attempt_when_empty = fifo_empty & r_en;

    // overflow flag: set when write attempted while full; clear on a successful read
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) fifo_overflow_flag <= 0;
        else if (write_attempt_when_full)
            fifo_overflow_flag <= 1;
        else if (fifo_r_en)
            fifo_overflow_flag <= 0;
    end

    // underflow flag: set when read attempted while empty; clear on a successful write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) fifo_underflow_flag <= 0;
        else if (read_attempt_when_empty)
            fifo_underflow_flag <= 1;
        else if (fifo_w_en)
            fifo_underflow_flag <= 0;
    end
endmodule

module Synchronous_FIFO_memory #(
    parameter DATASIZE = 8,
    parameter DEPTH = 16,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   w_en,
    input  wire                   r_en,
    input  wire [DATASIZE-1:0]    data_in,
    output wire [DATASIZE-1:0]    data_out,
    output wire                   fifo_full,
    output wire                   fifo_empty,
    output wire                   fifo_overflow_flag,
    output wire                   fifo_underflow_flag
);
    wire [PTR_WIDTH:0] w_ptr, r_ptr;
    wire fifo_w_en, fifo_r_en;

    Write_pointer #(.DATASIZE(DATASIZE), .DEPTH(DEPTH)) u_write_ptr (
        .w_en(w_en),
        .fifo_full(fifo_full),
        .clk(clk),
        .rst_n(rst_n),
        .fifo_w_en(fifo_w_en),
        .w_ptr(w_ptr)
    );

    Read_pointer #(.DATASIZE(DATASIZE), .DEPTH(DEPTH)) u_read_ptr (
        .r_en(r_en),
        .fifo_empty(fifo_empty),
        .clk(clk),
        .rst_n(rst_n),
        .fifo_r_en(fifo_r_en),
        .r_ptr(r_ptr)
    );

    Memory_Array #(.DATASIZE(DATASIZE), .DEPTH(DEPTH)) u_mem (
        .clk(clk),
        .fifo_w_en(fifo_w_en),
        .w_ptr(w_ptr),
        .r_ptr(r_ptr),
        .data_in(data_in),
        .fifo_r_en(fifo_r_en),
        .data_out(data_out)
    );

    Memory_State #(.DATASIZE(DATASIZE), .DEPTH(DEPTH)) u_state (
        .clk(clk),
        .rst_n(rst_n),
        .w_en(w_en),
        .r_en(r_en),
        .fifo_w_en(fifo_w_en),
        .fifo_r_en(fifo_r_en),
        .w_ptr(w_ptr),
        .r_ptr(r_ptr),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty),
        .fifo_overflow_flag(fifo_overflow_flag),
        .fifo_underflow_flag(fifo_underflow_flag)
    );
endmodule

