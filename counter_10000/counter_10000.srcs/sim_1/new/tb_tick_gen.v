`timescale 1ns / 1ps

module tb_tick_gen ();

    reg clk, rst;
    wire o_tick;

    clk_tick_gen dut (
        .clk(clk),
        .rst(rst),
        .o_tick(o_tick)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        #20;
        rst = 0;

        //200msec delay
        #200_000_000;
    end


endmodule
