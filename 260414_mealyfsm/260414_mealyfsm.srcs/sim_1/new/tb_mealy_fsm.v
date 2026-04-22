`timescale 1ns / 1ps

module tb_mealy_fsm ();

    reg  clk;
    reg  rst;
    reg  din_bit;
    wire dout_bit;

    mealy_fsm dut (
        .clk(clk),
        .rst(rst),
        .din_bit(din_bit),
        .dout_bit(dout_bit)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        din_bit = 0;

        #20 rst = 0;

        #5 din_bit = 0;
        #5 din_bit = 0;
        #5 din_bit = 1;
        #5 din_bit = 0;
        #5 din_bit = 1;
        #5 din_bit = 0;
        #5 din_bit = 1;
        #5 din_bit = 0;
        #5 din_bit = 0;
        #5 din_bit = 0;
        #5 din_bit = 1;
        #5 din_bit = 0;
        #5 din_bit = 1;
        #5 din_bit = 0;

        #20;

        $stop;
    end

endmodule
