`timescale 1ns / 1ps

module tb_adder_8bit ();
    reg [7:0] a, b;
    wire [7:0] s;
    wire c;

    integer i, j;  // 2state 0,1

    adder_8bit dut (
        .a(a),
        .b(b),
        .s(s),
        .c(c)   // cin process in
    );

    initial begin
        i = 0;
        j = 0;
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a = i;
                b = j;
                #10;
            end
        end
        $stop;
    end
endmodule
