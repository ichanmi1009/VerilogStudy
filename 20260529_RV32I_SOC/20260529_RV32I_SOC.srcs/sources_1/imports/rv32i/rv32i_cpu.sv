`timescale 1ns / 1ps

module rv32i_cpu (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    input  logic [31:0] RDATA,
    input  logic        READY,
    output logic [31:0] instr_addr,
    output logic [ 2:0] mem_mode,
    output logic        W_REQ,
    output logic        R_REQ,
    output logic [31:0] Addr,
    output logic [31:0] WDATA
);
    logic rf_we, pc_en, branch, alusrc_sel;
    logic [3:0] alu_control;
    logic [2:0] rfsrc_sel;
    logic       jal;
    logic       jalr;
    control_unit U_CONTROL_UNIT (.*);
    datapath U_DATA_PATH (.*);

endmodule

