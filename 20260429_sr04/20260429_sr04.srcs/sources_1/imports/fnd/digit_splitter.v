`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/08 13:03:58
// Design Name: 
// Module Name: digit_splitter
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


module digit_splitter(
    input   [13:0]   digit_in, //14bit
    output  [3:0]   digit_1,
    output  [3:0]   digit_10,
    output  [3:0]   digit_100,
    output  [3:0]   digit_1000
);

    assign digit_1      = digit_in % 10; //digit 1
    assign digit_10     = (digit_in / 10) % 10; //digit 10
    assign digit_100    = (digit_in / 100) % 10; //digit 100
    assign digit_1000   = (digit_in / 1000) % 10; //digit 1000



endmodule
