`timescale 1ns / 1ps
module gates(   // top module
    input  a,
    input  b, // input a, b
    output y0, // and output
    output y1, // nand
    output y2, // or
    output y3, // nor
    output y4, // xor
    output y5, // xnor
    output y6  // not
    );
    assign y0 = a & b; // & : and operator
    assign y1 = ~(a & b); // ~ : not
    assign y2 = (a | b); // | : OR operator
    assign y3 = ~(a | b); // ~ : not
    assign y4 = (a ^ b); // ^ : hat, exor operator
    assign y5 = ~(a ^ b); // ex nor
    assign y6 = ~a; // ~ : not


endmodule
