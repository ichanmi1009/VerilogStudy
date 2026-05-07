`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/08 11:01:28
// Design Name: 
// Module Name: mux_4x1
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


module mux_4x1(
    input       [3:0]   in0,    //digit 1
    input       [3:0]   in1,    //digit 10  
    input       [3:0]   in2,    //digit 100
    input       [3:0]   in3,    //digit 1000
    input       [1:0]   sel,    //to select input
    output      [3:0]   out_mux
);
    reg [3:0]   out_reg;
    assign out_mux = out_reg;

    //mux, (*) all input : sensitivity list
    always @(*) begin
        case(sel)
            2'b00   : out_reg = in0;
            2'b01   : out_reg = in1;
            2'b10   : out_reg = in2;            
            2'b11   : out_reg = in3;
            default : out_reg = 4'bxxxx; // 4'b0000 
        endcase        
    end

endmodule
