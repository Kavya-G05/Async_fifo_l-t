`timescale 1ns / 1ps

module testbench();

    parameter WIDTH = 4, DEPTH = 8;

    // Signals for FIFO testbench
    reg clk_in;
    reg rst_n;
    reg wr_rq, rd_rq;
    wire full, empty;
    reg [WIDTH-1:0] wdata;
    wire [WIDTH-1:0] rdata;

    // Internal variables for FIFO verification
    reg [WIDTH-1:0] fifo [0:DEPTH-1]; // Verification FIFO
    reg [$clog2(DEPTH)-1:0] wptr = 0; // Write pointer
    reg [$clog2(DEPTH)-1:0] rptr = 0;  // Read pointer

    // Clock divider signals
    wire w_clk;
    wire r_clk;

    // Instantiate the FIFO top module
    tt_um_Kavya #(WIDTH, DEPTH) fifo_inst (
        .clk_in(clk_in),
        .rst_n(rst_n),
        .wr_rq(wr_rq),
        .rd_rq(rd_rq),
        .wdata(wdata),
        .rdata(rdata),
        .full(full),
        .empty(empty)
    );

    // Instantiate the clock divider module
    clock_divider clock_div_inst (
        .clk_in(clk_in),
        .reset(~rst_n), // Active-high reset for clock divider
        .w_clk(w_clk),
        .r_clk(r_clk)
    );

    // Generate input clock (100 MHz = 10 ns period)
    initial begin
        clk_in = 0;
        forever #5 clk_in = ~clk_in;
    end

    initial begin
        rst_n = 1;
        wr_rq = 0;
        rd_rq = 0;
        wdata = 0;
        #10 rst_n = 0;  
        #20 rst_n = 1;  

        #13 wr_rq=1;rd_rq=1;
        fork
            // Write operation
            repeat (150) begin
                @(posedge w_clk);
                if (!full) begin
                    wdata = $random();           
                    fifo[wptr] = wdata;     
                    wptr = (wptr + 1) % DEPTH; 
                end
                             
                
                #10; 
            end

            
            forever begin
                @(posedge r_clk);
                if (!empty && rd_rq) begin               
                    rptr = (rptr + 1) % DEPTH; 
                end
               
            end
        join        
    end

   
endmodule
