
// OP-CODE instruction code [6:0]
`define R_TYPE 7'b011_0011
`define S_TYPE 7'b010_0011
`define IL_TYPE 7'b000_0011
`define I_TYPE 7'b001_0011
`define B_TYPE 7'b110_0011
`define UL_TYPE 7'b011_0111 // LUI (Load Upper Immediate)
`define UA_TYPE 7'b001_0111 // AUIPC (Add Upper Immediate to PC)
`define J_TYPE 7'b110_1111 // JAL (Jump and Link)
`define JL_TYPE 7'b110_0111 // JALR (Jump and Link Register)

// R-type instruction
// {funct7, funct3} = 10bit
// optimize {funct7[5], funct3} = 4bit
`define ADD 4'b0_000
`define SUB 4'b1_000
`define SLL 4'b0_001
`define SLT 4'b0_010
`define SLTU 4'b0_011
`define XOR 4'b0_100
`define SRL 4'b0_101
`define SRA 4'b1_101
`define OR 4'b0_110
`define AND 4'b0_111

// S-type instruction
`define SB 3'b000
`define SH 3'b001
`define SW 3'b010

// IL-type instruction
`define LB 3'b000
`define LH 3'b001
`define LW 3'b010
`define LBU 3'b100
`define LHU 3'b101

// I-type instruction
`define ADDI 4'b0_000
`define SUBI 4'b1_000
`define SLLI 4'b0_001
`define SLTI 4'b0_010
`define SLTUI 4'b0_011
`define XORI 4'b0_100
`define SRLI 4'b0_101
`define SRAI 4'b1_101
`define ORI 4'b0_110
`define ANDI 4'b0_111

// B-type instruction
`define BEQ 3'b000
`define BNE 3'b001
`define BLT 3'b100
`define BGE 3'b101
`define BLTU 3'b110
`define BGEU 3'b111

