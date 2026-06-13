`timescale 1ns / 1ps

module instruction_mem (
    input  logic [31:0] instr_addr,
    output logic [31:0] instr_code
);

    logic [31:0] instr_rom[0:15];

    initial begin
        instr_rom[0] = 32'h003202b3;  // ADD (x5 = x4 + x3)
        instr_rom[1] = 32'h40d283b3;  // SUB (x7 = x5 - x13)
        instr_rom[2] = 32'h002096b3;  // SLL (x13 = x1 << x2)
        instr_rom[3] = 32'h0013a433;  // SLT (x8 = x7 < x1) ? 1 : 0
        instr_rom[4] = 32'h0013b2b3;  // SLTU (x5 = x7 < x1) ? 1 : 0
        instr_rom[5] = 32'h0020c4b3;  // XOR (x9 = x1 ^ x2)
        instr_rom[6] = 32'h0023d533;  // SRL (x10 = x7 >> x2)
        instr_rom[7] = 32'h4023d5b3;  // SRA (x11 = x7 >>> x2)
        instr_rom[8] = 32'h00276333;  // OR (x6 = x14 | x2)
        instr_rom[9] = 32'h0020F633;  // AND (x12 = x1 & x2)
    end

    assign instr_code = instr_rom[instr_addr[31:2]];

endmodule
