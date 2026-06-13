`timescale 1ns / 1ps

module apb_master_controlunit (
    input         clk,
    input         rst,
    input  [31:0] instr_code,
    input         ready,
    input  [31:0] rdata,
    output [31:0] instr_addr,
    output [31:0] addr,
    output [31:0] wdata,
    output        wreq,
    output        rreq
);
endmodule
