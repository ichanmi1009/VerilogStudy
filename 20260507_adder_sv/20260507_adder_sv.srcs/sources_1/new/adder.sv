`timescale 1ns / 1ps

module adder (
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic       mode,  // 0:sum, 1:sub
    output logic [7:0] s,
    output logic       c
);

    assign {c, s} = (mode) ? a - b : a + b;

endmodule
