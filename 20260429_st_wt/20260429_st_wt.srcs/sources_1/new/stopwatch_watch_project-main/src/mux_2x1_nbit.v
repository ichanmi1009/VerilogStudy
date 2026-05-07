`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/17 21:06:40
// Design Name: 
// Module Name: mux_2x1_nbit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mux_2x1_nbit#(
    parameter WIDTH = 8
)(
    input   [WIDTH - 1 : 0]     in0,
    input   [WIDTH - 1 : 0]     in1,
    input                       sel,
    output  [WIDTH - 1 : 0]     y   
);

    assign y = (sel) ? in1 : in0;



endmodule
