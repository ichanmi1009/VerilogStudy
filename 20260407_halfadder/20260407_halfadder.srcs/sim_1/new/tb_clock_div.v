`timescale 1ns / 1ps

module tb_clock_div ();

    reg clk, rst;
    wire o_1khz;

    clk_div_1khz dut (
        .clk(clk),
        .rst(rst),
        .o_1khz(o_1khz)
    );

    always #5 clk = ~clk;  // 5n 반전 10m

    initial begin
        clk = 0;
        rst = 1;

        #20;
        rst = 0;
    end

endmodule

