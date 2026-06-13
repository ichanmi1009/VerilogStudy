`timescale 1ns / 1ps

module top_rv32i_soc (
    input clk,
    input rst
);

    logic [31:0] instr_code;
    logic [31:0] instr_addr;
    logic [31:0] daddr;
    logic [31:0] dwdata;
    logic [31:0] drdata;
    logic [ 2:0] mem_mode;
    logic        dwe;

    instruction_mem U_INSTR_ROM (.*);
    rv32i_cpu U_RV32I_CPU (.*);
    data_mem U_DATA_RAM (.*);

endmodule
