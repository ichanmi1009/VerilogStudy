`timescale 1ns / 1ps  // 빠르게 100p

module tb_stopwatch_datapath ();

    parameter SEC_DELAY = 1_000_000;
    parameter MIN_DELAY = 60_000_000;

    reg clk, rst, i_runstop, i_clear, i_mode;
    wire [6:0] msec;
    wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;


    stopwatch_datapath dut (
        .clk(clk),
        .rst(rst),
        .i_runstop(i_runstop),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );

    always #5 clk = ~clk;
    initial begin
        clk = 0;
        rst = 1;
        i_runstop = 0;
        i_clear = 0;
        i_mode = 0;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        rst = 0;
        i_runstop = 1;
        repeat (10) #(SEC_DELAY);
        i_clear = 1;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        i_clear = 0;
        #(SEC_DELAY);

        i_mode = 1;
        #(MIN_DELAY);

        //repeat (10_000_000) @(negedge clk);

        $stop;
    end


endmodule
