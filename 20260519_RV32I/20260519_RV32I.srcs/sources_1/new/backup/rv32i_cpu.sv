`timescale 1ns / 1ps

module rv32i_cpu (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    output logic [31:0] instr_addr
);
    logic rf_we;
    logic [3:0] alu_control;

    control_unit U_CONTROL_UNIT (
        .funct7(instr_code[31:25]),
        .funct3(instr_code[14:12]),
        .opcode(instr_code[6:0]),
        .*
    );
    datapath U_DATA_PATH (.*);

endmodule
