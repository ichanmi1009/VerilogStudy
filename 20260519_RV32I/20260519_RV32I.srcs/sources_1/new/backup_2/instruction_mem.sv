`timescale 1ns / 1ps

module instruction_mem (
    input  logic [31:0] instr_addr,
    output logic [31:0] instr_code
);

    logic [31:0] instr_rom[0:15];

    initial begin
        //instr_rom[0] = 32'h0031_02b3;  // R_TYPE : ADD (x5 = x4 + x3)
        //instr_rom[1] = 32'h0041_82b3;  // R_TYPE : SUB (x7 = x5 - x13)
        //instr_rom[2] = 32'h0031_2123;  // S_TYPE : sw x2, x3, 2 : rs1, rs2, imm
        //instr_rom[3] = 32'h0021_2403;  // I_TYPE : lw x8, x2, 2 : rd, rs1, imm

        // I_TYPE
        // ADDI
        // 
        instr_rom[0] = 32'hffd50313;  // I_TYPE : ADDI
        instr_rom[1] = 32'hffb7a113;
        instr_rom[2] = 32'hffb7b193;
        instr_rom[3] = 32'h00338123;
    end

    assign instr_code = instr_rom[instr_addr[31:2]];

endmodule
