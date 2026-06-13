`timescale 1ns / 1ps
`include "define.vh"

module datapath (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    input  logic        rf_we,
    input  logic        alusrc_sel,
    input  logic [ 3:0] alu_control,
    input  logic        rfsrc_sel,
    input  logic [31:0] drdata,
    output logic [31:0] instr_addr,
    output logic [31:0] daddr,
    output logic [31:0] dwdata
);
    logic [31:0] rs1, rs2, alu_result, rfsrc_mux_out;
    logic [31:0] imm_extend, alu_rs2_mux;

    assign daddr  = alu_result;
    assign dwdata = rs2;

    mux_2x1 U_REG_FILE_SRC_MUX (
        .in0    (alu_result),
        .in1    (drdata),
        .sel    (rfsrc_sel),
        .out_mux(rfsrc_mux_out)
    );

    register_file U_REG_FILE (
        .clk   (clk),
        .raddr1(instr_code[19:15]),
        .raddr2(instr_code[24:20]),
        .rf_we (rf_we),
        .waddr (instr_code[11:7]),
        .wdata (rfsrc_mux_out),
        .rdata1(rs1),
        .rdata2(rs2)
    );

    alu U_ALU (
        .alu_control(alu_control),
        .rs1        (rs1),          // rs1
        .rs2        (alu_rs2_mux),  // rs2
        .alu_result (alu_result)    // rd
    );


    mux_2x1 U_ALU_RS2_MUX (
        .in0    (rs2),
        .in1    (imm_extend),
        .sel    (alusrc_sel),
        .out_mux(alu_rs2_mux)
    );

    imm_extend U_IMM_EXTEND (
        .instr_code(instr_code),
        .imm_extend(imm_extend)
    );

    mux_2x1 U_PC_MUX (
        .in0    (imm_extend),
        .in1    (4),
        .sel    (b_taken),
        .out_mux(pc_mux_out)
    );

    program_counter U_PC (
        .clk   (clk),
        .rst   (rst),
        .pc_in (instr_addr),  // for next program count
        .pc_out(instr_addr)   // count program
    );

endmodule

module program_counter (
    input logic clk,
    input logic rst,
    input logic [31:0] pc_in,
    output logic [31:0] pc_out
);
    logic [31:0] pc_reg;
    assign pc_out = pc_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            pc_reg <= 0;
        end else begin
            pc_reg <= pc_in + 4;
        end
    end


endmodule

module mux_2x1 (
    input  logic [31:0] in0,
    input  logic [31:0] in1,
    input  logic        sel,
    output logic [31:0] out_mux
);

    assign out_mux = (sel) ? in1 : in0;

    /*always_comb begin
        case (sel)
            1'b0: out_mux = in0;
            1'b1: out_mux = in1;
        endcase

    end*/
endmodule



module imm_extend (
    input  logic [31:0] instr_code,
    output logic [31:0] imm_extend
);

    always_comb begin
        imm_extend = 32'd0;
        case (instr_code[6:0])
            `S_TYPE:
            imm_extend = {
                {20{instr_code[31]}}, instr_code[31:25], instr_code[11:7]
            };
            `IL_TYPE, `I_TYPE: begin
                imm_extend = {{20{instr_code[31]}}, instr_code[31:20]};
            end
            `B_TYPE: begin
                imm_extend = {
                    {20{instr_code[31]}},
                    instr_code[12],
                    instr_code[11],
                    instr_code[10:5],
                    instr_code[4:1]
                };
            end
        endcase
    end

endmodule


module alu (
    input logic [3:0] alu_control,
    input logic [31:0] rs1,  // rs1
    input logic [31:0] rs2,  // rs2
    output logic [31:0] alu_result
);
    always_comb begin
        alu_result = 32'd0;
        case (alu_control)
            // R-type RD = RS1 + RS2
            // I-type RD = RS1 + IMM(RS2)
            `ADD:  alu_result = rs1 + rs2;
            `SUB:  alu_result = rs1 - rs2;
            `SLL:  alu_result = rs1 << rs2;
            `SLT:  alu_result = $signed(rs1) < $signed(rs2) ? 1 : 0;
            `SLTU: alu_result = (rs1 < rs2) ? 1 : 0;
            `XOR:  alu_result = rs1 ^ rs2;
            `SRL:  alu_result = rs1 >> rs2[4:0];
            `SRA:  alu_result = $signed(rs1) >> rs2[4:0];  // [4:0]추가
            `OR:   alu_result = rs1 | rs2;
            `AND:  alu_result = rs1 & rs2;
        endcase
    end

endmodule


module register_file (
    input  logic        clk,
    input  logic [ 4:0] raddr1,  // rs1
    input  logic [ 4:0] raddr2,  // rs2
    input  logic        rf_we,   // register file write enable
    input  logic [ 4:0] waddr,   // rd
    input  logic [31:0] wdata,   // rd write data 
    output logic [31:0] rdata1,  // rs1 read data
    output logic [31:0] rdata2   // rs2 read data
);

    logic [31:0] register_file[1:31];  // 0은 항상 1로 초기화

    int i = 0;

    initial begin
        for (i = 1; i < 32; i++) begin
            register_file[i] = i;
        end
    end

    always_ff @(posedge clk) begin
        if (rf_we) begin
            register_file[waddr] <= wdata;
        end
    end

    assign rdata1 = (raddr1 != 0) ? register_file[raddr1] : 32'd0;
    assign rdata2 = (raddr2 != 0) ? register_file[raddr2] : 32'd0;

endmodule
