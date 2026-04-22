`timescale 1ns / 1ps


module tb_fnd ();
    reg clk;
    reg rst;
    reg [7:0] a;
    reg [7:0] b;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire led;


    integer i, j;


    adder_fnd dut (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .led(led)
    );

    // generate clock

    always #5 clk = ~clk;  // 5n마다 클럭 반전시켜라

    initial begin
        clk = 0;
        rst = 1;
        a   = 8'd0;
        b   = 8'd0;

        #20
        // reset
        rst = 0;

        #4_000_000;
        a = 255;
        b = 1;

        #4_000_000;
        a = 1;
        b = 255;

        #4_000_000;
        a = 255;
        b = 255;

        #4_000_000;
        //expexted s = 255, c = 0
        a = 0;
        b = 255;
        #1000;

        $stop;

    end


endmodule
