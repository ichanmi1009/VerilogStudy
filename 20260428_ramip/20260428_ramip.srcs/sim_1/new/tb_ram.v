`timescale 1ns / 1ps

module tb_ram ();

    reg clk, we;
    reg  [3:0] addr;
    reg  [7:0] wdata;
    wire [7:0] rdata;

    ram dut (
        .clk(clk),
        .addr(addr),
        .wdata(wdata),
        .we(we),
        .rdata(rdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk  = 0;
        addr = 0;
        we   = 0;

        // write
        we   = 1;
        @(negedge clk);
        addr  = 10;
        wdata = 8'h0a;
        @(negedge clk);
        addr  = 11;
        wdata = 8'h0b;
        @(negedge clk);
        addr  = 14;
        wdata = 8'h0c;
        @(negedge clk);
        addr  = 15;
        wdata = 8'h0d;

        // read
        @(negedge clk);
        we   = 0;
        addr = 10;
        @(negedge clk);
        addr = 11;
        @(negedge clk);
        addr = 14;
        @(negedge clk);
        addr = 15;

        #20;
        $stop;

    end


endmodule
