`timescale 1ns / 1ps

module tb_tick_gen_100hz ();

    reg clk, rst;
    wire o_tick_100hz;

    tick_gen_100hz dut (
        .clk(clk),
        .rst(rst),
        .o_tick_100hz(o_tick_100hz)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);

        rst = 0;

        repeat (1_100_000) @(negedge clk);
        $stop;

    end

endmodule
