
// OP-CODE instruction code [6:0]
`define R_TYPE 7'b011_0011


// R-type instruction
// {funct7, funct3} = 10bit
`define ADD 4'b0000
`define SUB 4'b1000
`define SLL 4'b0001
`define SLT 4'b0010
`define SLTU 4'b0011
`define XOR 4'b0100
`define SRL 4'b0101
`define SRA 4'b1101
`define OR 4'b0110
`define AND 4'b0111
