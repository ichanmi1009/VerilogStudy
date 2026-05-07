`timescale 1ns / 1ps

module mux_2x1_nbit #(
    parameter WIDTH = 8
) (
    input  [WIDTH - 1 : 0] in0,
    input  [WIDTH - 1 : 0] in1,
    input                  sel,
    output [WIDTH - 1 : 0] y
);

    assign y = (sel) ? in1 : in0;



endmodule
