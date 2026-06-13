`timescale 1ns / 1ps

module tb_counter ();

    reg        clk;
    reg        rst;
    reg        load;
    reg  [7:0] data_in;
    reg        en;
    wire [7:0] count;
    wire       tick;

    counter dut (
        .clk(clk),
        .rst(rst),
        .load(load),
        .data_in(data_in),
        .en(en),
        .count(count),
        .tick(tick)
    );

    always #5 clk = ~clk;

    initial begin
        clk  = 0;
        rst  = 1;
        load = 0;
        en   = 0;

        #10;
        rst = 0;
        #10;
        en = 1;
        #10;
        load = 1;
        data_in = 8'd3;
        #10;
        load = 0;
        #40;
    end

endmodule
