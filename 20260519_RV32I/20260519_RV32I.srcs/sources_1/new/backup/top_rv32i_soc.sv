`timescale 1ns / 1ps

module top_rv32i_soc (
    input clk,
    input rst
);

    logic [31:0] instr_code;
    logic [31:0] instr_addr;

    instruction_mem U_INSTR_ROM (.*);
    rv32i_cpu U_RV32I_CPU (.*);

endmodule
