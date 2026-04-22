`timescale 1ns / 1ps

module tb_full_adder_4bit ();
    reg [3:0] a, b;
    wire [3:0] s;
    wire c;

    integer i, j;  // 2state 0,1

    full_adder_4bit dut (
        .a  (a),
        .b  (b),
        .cin(1'b0),  // 1'b0:1bit'b:binary , 1'h0 : 1bit, h :hexa
        .s  (s),
        .c  (c)
    );

    initial begin
        i = 0;
        j = 0;
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                a = i;
                b = j;
                #10;
            end
        end
        $stop;
    end



endmodule
