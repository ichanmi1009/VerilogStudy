`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/08 14:26:58
// Design Name: 
// Module Name: counter_4
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


module counter_4(
    input                   clk,
    input                   rst,
    output  [1:0]           digit_sel
);
    reg [1:0]   counter_reg;

    assign digit_sel = counter_reg;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            counter_reg <= 2'b00;
        end
        else begin
            counter_reg <= counter_reg + 1'b1;
        end
    end

    
endmodule
