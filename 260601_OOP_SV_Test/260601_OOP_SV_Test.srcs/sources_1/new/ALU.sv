`timescale 1ns / 1ps

module ALU (
    input  logic       opcode,
    input  logic [7:0] A,
    input  logic [7:0] B,
    output logic [7:0] result
);

    always_comb begin
        case (opcode)
            1'b0: result = A + B;  // add
            1'b1: result = A - B;  // sub
            default: result = 8'b0;
        endcase
    end
endmodule
