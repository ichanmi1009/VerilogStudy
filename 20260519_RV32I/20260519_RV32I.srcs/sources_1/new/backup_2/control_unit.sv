`timescale 1ns / 1ps

`include "define.vh"

module control_unit (
    input  logic [31:0] instr_code,
    output logic        rf_we,
    output logic        alusrc_sel,
    output logic [ 3:0] alu_control,
    output logic        rfsrc_sel,
    output logic [ 2:0] mem_mode,
    output logic        dwe
);
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [6:0] opcode;

    assign opcode = instr_code[6:0];
    assign funct3 = instr_code[14:12];
    assign funct7 = instr_code[31:25];

    // [DEBUG]
    typedef enum logic [6:0] {
        DBG_R_TYPE  = `R_TYPE,
        DBG_S_TYPE  = `S_TYPE,
        DBG_IL_TYPE = `IL_TYPE,
        DBG_I_TYPE  = `I_TYPE
    } opcode_dbg_e;
    opcode_dbg_e opcode_dbg;
    assign opcode_dbg = opcode_dbg_e'(opcode);


    always_comb begin
        rf_we       = 0;
        alusrc_sel  = 0;
        alu_control = 0;
        rfsrc_sel   = 0;
        mem_mode    = 3'b0;
        dwe         = 0;
        case (opcode)
            `R_TYPE: begin
                rf_we       = 1'b1;
                alusrc_sel  = 1'b0;
                alu_control = {funct7[5], funct3};
                rfsrc_sel   = 0;
                mem_mode    = 3'b0;
                dwe         = 0;  // don't care = 0으로 처리
            end
            `S_TYPE: begin
                rf_we = 1'b0;  // 데이터 레지스터에 다시 저장 X
                alusrc_sel = 1'b1;  // rs1 + imm
                alu_control = `ADD;
                rfsrc_sel = 0;
                mem_mode = funct3;  // 나중에 사용하기 위함
                dwe = 1;
            end
            `IL_TYPE: begin
                rf_we       = 1'b1;
                alusrc_sel  = 1'b1;  // rs1 + imm
                alu_control = `ADD;
                rfsrc_sel   = 1;  // from data memory
                mem_mode    = funct3;  // 나중에 사용하기 위함
                dwe         = 1'b0;  // 메모리에 write 하면 안됨
            end
            `I_TYPE: begin  // imm 0~4까지 가져와서써라(shamt), 그 위는 r_type처럼 윗 비트 가져와서 명령어 분리하는데 사용해도 가능
                rf_we      = 1'b1;
                alusrc_sel = 1'b1;  // rs1 + imm
                if (funct3 == 3'b101) begin
                    alu_control = {funct7[5], funct3};
                end else begin
                    alu_control = {1'b0, funct3};
                end
                rfsrc_sel = 0;  // alu result
                mem_mode  = 0;  // don't care
                dwe       = 1'b0;  // 메모리에 write 하면 안됨
            end
        endcase
    end
endmodule
