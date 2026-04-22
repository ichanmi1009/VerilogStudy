`timescale 1ns / 1ps

module tb_datapath ();

    reg clk, rst;
    wire [13:0] tick_counter;

    datapath U_DATAPATH (
        .rst(rst),
        .clk(clk),
        .o_tick_counter(tick_counter)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        #20;
        rst = 0;

        //500msec delay
        #500_000_000;
        $stop;
    end


endmodule
