`timescale 1ns / 1ps

module tb_rv32i ();

    logic clk, rst;

    top_rv32i_soc dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        @(negedge clk);
        @(negedge clk);
        rst = 0;
        repeat (1000) @(negedge clk);
    end

endmodule
