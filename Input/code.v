`timescale 1ns / 1ps
module clock_divider(
    input clk_in,        // Input clock (assumed 60 MHz for this example)
    input reset,         // Synchronous reset
    output reg w_clk,   // 50 MHz write clock output
    output reg r_clk    // 30 MHz read clock output
);

    reg [2:0] wr_counter = 3'b000;  // Counter for write clock division
    reg [2:0] rd_counter = 3'b000; // Counter for read clock division

    // Generate 50 MHz clock (divide by 1.2)
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            wr_counter <= 3'b000;
            w_clk <= 1'b0;
        end else if (wr_counter == 1) begin
            wr_counter <= 3'b000;
            w_clk <= ~w_clk;
        end else begin
            wr_counter <= wr_counter + 1'b1;
        end
    end

    // Generate 30 MHz clock (approximate divide by 2)
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            rd_counter <= 3'b000;
            r_clk <= 1'b0;
        end else if (rd_counter == 2) begin
            rd_counter <= 3'b000;
            r_clk <= ~r_clk;
        end else begin
            rd_counter <= rd_counter + 1'b1;
        end
    end
endmodule
module empty
#(
    parameter WIDTH = 4,   
    parameter DEPTH = 8  
)
(
    input wire r_clk,             
    input wire rst_n,              
    input wire rd_rq,              
    input wire [$clog2(DEPTH):0] rsync_ptr2, 
    output reg [$clog2(DEPTH)-1:0] raddr,    
    output reg [$clog2(DEPTH):0] rptr,       
    output reg empty                          
);
reg [$clog2(DEPTH):0] bin, binnext, graynext;
reg emptyn;
always @(posedge r_clk or negedge rst_n) begin
        if (~rst_n) begin
            rptr <= 'd0;       
            bin <= 'd0;        
            empty <= 1;       
        end else begin
            rptr <= graynext;  
            bin <= binnext;    
            empty <= emptyn;   
        end
end
always @(*) begin
        raddr = bin[$clog2(DEPTH)-1:0];
        binnext = bin + (~empty & rd_rq);
        graynext = (binnext >> 1) ^ binnext;
        emptyn = (graynext == rsync_ptr2);
end
endmodule
module fifo_mem 
#(
  parameter WIDTH = 4,
  parameter DEPTH = 8
)
(
  input wire w_clk,r_clk,
  input wire wr_rq,
  input wire rd_rq,
  input wire full,
  input wire empty,
  input wire [$clog2(DEPTH)-1:0] waddr,
  input wire [$clog2(DEPTH)-1:0] raddr,
  input wire [WIDTH-1:0] wdata,
  output reg [WIDTH-1:0] rdata
);

reg [WIDTH-1:0] fifo [0:DEPTH-1];


always @(posedge w_clk) begin
    if (wr_rq && !full) begin
      fifo[waddr] <= wdata;
    end
end
always @(posedge r_clk) begin
    if (rd_rq && !empty) begin
      rdata <= fifo[raddr];
    end else begin
      rdata = {WIDTH{1'b0}};
    end
end

endmodule


module full
#(parameter WIDTH = 4,
  parameter DEPTH = 8)
(
  input wire w_clk,
  input wire rst_n,
  input wire wr_rq,
  input wire [$clog2(DEPTH):0] wsync_ptr2,
  output reg [$clog2(DEPTH)-1:0] waddr,
  output reg [$clog2(DEPTH):0] wptr,
  output reg full
);

  reg [$clog2(DEPTH):0] bin, binnext, graynext;
  reg fulln;
always @(posedge w_clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr <= 'd0;
      bin <= 'd0;
      full <= 0;
    end else begin
      wptr <= graynext; 
      bin <= binnext;  
      full <= fulln;    
    end
end
always @(*) begin
   waddr = bin[$clog2(DEPTH)-1:0];
   binnext = bin + (~full & wr_rq);
   graynext = (binnext >> 1) ^ binnext;
   fulln = (graynext == {~wsync_ptr2[$clog2(DEPTH):$clog2(DEPTH)-1], wsync_ptr2[$clog2(DEPTH)-2:0]});
end

endmodule
module sync_r2w #(parameter DEPTH = 8) (
    input wire w_clk,               
    input wire rst_n,               
    input wire [$clog2(DEPTH):0] rptr, 
    output reg [$clog2(DEPTH):0] wsync_ptr2 
);
reg [$clog2(DEPTH):0] wsync_ptr1;
always @(posedge w_clk or negedge rst_n) begin
    if (!rst_n) begin
        wsync_ptr1 <= 'd0;
        wsync_ptr2 <= 'd0;
    end else begin
        wsync_ptr1 <= rptr;
        wsync_ptr2 <= wsync_ptr1;
    end
end
endmodule

module sync_w2r #(parameter DEPTH = 8) (
    input wire r_clk,               
    input wire rst_n,              
    input wire [$clog2(DEPTH):0] wptr,  
    output reg [$clog2(DEPTH):0] rsync_ptr2 
);
reg [$clog2(DEPTH):0] rsync_ptr1;
always @(posedge r_clk or negedge rst_n) begin
        if (!rst_n) begin
            rsync_ptr1 <= 'd0;
            rsync_ptr2 <= 'd0;
        end else begin
            rsync_ptr1 <= wptr;
            rsync_ptr2 <= rsync_ptr1;
        end
end
endmodule
module tt_um_Kavya
#(parameter WIDTH = 4, 
  parameter DEPTH = 8
)
(
    input wire clk_in,          // Input clock for clock divider
    input wire rst_n,           // Active-low reset
    input wire wr_rq,           // Write request
    input wire rd_rq,           // Read request
    input wire [WIDTH-1:0] wdata, // Write data
    output wire full,           // FIFO full flag
    output wire empty,          // FIFO empty flag
    output wire [WIDTH-1:0] rdata // Read data
);

    // Internal clock signals generated by clock divider
    wire w_clk; // Write clock
    wire r_clk; // Read clock

    // Internal wires for FIFO control and synchronization
    wire [$clog2(DEPTH)-1:0] waddr;    // Write address
    wire [$clog2(DEPTH)-1:0] raddr;    // Read address
    wire [$clog2(DEPTH):0] wptr;       // Write pointer
    wire [$clog2(DEPTH):0] rptr;       // Read pointer
    wire [$clog2(DEPTH):0] wsync_ptr2; // Synchronized read pointer in write clock domain
    wire [$clog2(DEPTH):0] rsync_ptr2; // Synchronized write pointer in read clock domain

    // Instantiate the clock divider
    clock_divider clk_div_inst (
        .clk_in(clk_in),
        .reset(~rst_n),
        .w_clk(w_clk),
        .r_clk(r_clk)
    );

    // Instantiate synchronization and FIFO modules

    sync_r2w #(.DEPTH(DEPTH)) sync_r2w_inst (
        .rptr(rptr),
        .w_clk(w_clk),
        .rst_n(rst_n),
        .wsync_ptr2(wsync_ptr2)
    );

    sync_w2r #(.DEPTH(DEPTH)) sync_w2r_inst (
        .wptr(wptr),
        .r_clk(r_clk),
        .rst_n(rst_n),
        .rsync_ptr2(rsync_ptr2)
    );

    fifo_mem #(.WIDTH(WIDTH), .DEPTH(DEPTH)) fifomem_inst (
        .w_clk(w_clk),
        .r_clk(r_clk),
        .wr_rq(wr_rq),
        .rd_rq(rd_rq),
        .full(full),
        .empty(empty),
        .waddr(waddr),
        .raddr(raddr),
        .wdata(wdata),
        .rdata(rdata)
    );

    full #(.WIDTH(WIDTH), .DEPTH(DEPTH)) full_inst (
        .w_clk(w_clk),
        .rst_n(rst_n),
        .wr_rq(wr_rq),
        .wsync_ptr2(wsync_ptr2),
        .waddr(waddr),
        .wptr(wptr),
        .full(full)
    );

    empty #(.WIDTH(WIDTH), .DEPTH(DEPTH)) empty_inst (
        .r_clk(r_clk),
        .rst_n(rst_n),
        .rd_rq(rd_rq),
        .rsync_ptr2(rsync_ptr2),
        .raddr(raddr),
        .rptr(rptr),
        .empty(empty)
    );

endmodule
