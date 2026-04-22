`timescale 1ns / 1ps

// To test simulation environment module
module tb_gates ();

    reg a, b;
    wire y0, y1, y2, y3, y4, y5, y6;

    gates dut (
        .a (a),
        .b (b),   // input a, b
        .y0(y0),  // and output
        .y1(y1),  // nand
        .y2(y2),  // or
        .y3(y3),  // nor
        .y4(y4),  // xor
        .y5(y5),  // xnor
        .y6(y6)   // not
    );

    initial begin
        a = 0;
        b = 0;
        #10;
        a = 0;
        b = 1;
        #10 a = 1;
        b = 0;
        #10 a = 1;
        b = 1;
        $finish;
    end

endmodule
