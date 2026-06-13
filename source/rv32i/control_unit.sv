`timescale 1ns / 1ps

`include "define.vh"

module control_unit (
    input  logic [31:0] instr_code,
    output logic        rf_we,
    output logic        branch,
    output logic        jal,
    output logic        jalr,
    output logic        alusrc_sel,
    output logic [ 3:0] alu_control,
    output logic [ 2:0] rfsrc_sel,
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
        DBG_I_TYPE  = `I_TYPE,
        DBG_B_TYPE  = `B_TYPE,
        DBG_UL_TYPE = `UL_TYPE,
        DBG_UA_TYPE = `UA_TYPE,
        DBG_J_TYPE  = `J_TYPE,
        DBG_JL_TYPE = `JL_TYPE
    } opcode_dbg_e;
    opcode_dbg_e opcode_dbg;
    assign opcode_dbg = opcode_dbg_e'(opcode);

    typedef enum logic [3:0] {
        DBG_ADD  = `ADD,
        DBG_SUB  = `SUB,
        DBG_SLL  = `SLL,
        DBG_SLT  = `SLT,
        DBG_SLTU = `SLTU,
        DBG_XOR  = `XOR,
        DBG_SRL  = `SRL,
        DBG_SRA  = `SRA,
        DBG_OR   = `OR,
        DBG_AND  = `AND
    } r_type_dbg_e;
    r_type_dbg_e r_type_dbg;

    typedef enum logic [3:0] {
        DBG_ADDI  = `ADDI,
        DBG_SLLI  = `SLLI,
        DBG_SLTI  = `SLTI,
        DBG_SLTUI = `SLTUI,
        DBG_XORI  = `XORI,
        DBG_SRLI  = `SRLI,
        DBG_SRAI  = `SRAI,
        DBG_ORI   = `ORI,
        DBG_ANDI  = `ANDI
    } i_type_dbg_e;
    i_type_dbg_e i_type_dbg;

    typedef enum logic [3:0] {
        DBG_BEQ  = `BEQ,
        DBG_BNE  = `BNE,
        DBG_BLT  = `BLT,
        DBG_BGE  = `BGE,
        DBG_BLTU = `BLTU,
        DBG_BGEU = `BGEU
    } b_type_dbg_e;
    b_type_dbg_e b_type_dbg;

    typedef enum logic [2:0] {
        DBG_LB  = `LB,
        DBG_LH  = `LH,
        DBG_LW  = `LW,
        DBG_LBU = `LBU,
        DBG_LHU = `LHU
    } il_type_dbg_e;
    il_type_dbg_e il_type_dbg;

    typedef enum logic [1:0] {
        DBG_SB = `SB,
        DBG_SH = `SH,
        DBG_SW = `SW
    } s_type_dbg_e;
    s_type_dbg_e s_type_dbg;

    assign r_type_dbg = r_type_dbg_e'(alu_control);
    assign i_type_dbg  = (opcode == `I_TYPE) ? i_type_dbg_e'(alu_control) : i_type_dbg_e'('x);
    assign il_type_dbg = (opcode == `IL_TYPE) ? il_type_dbg_e'(funct3) : il_type_dbg_e'('x);
    assign s_type_dbg  = (opcode == `S_TYPE) ? s_type_dbg_e'(funct3) : s_type_dbg_e'('x);
    assign b_type_dbg = (opcode == `B_TYPE) ? b_type_dbg_e'(alu_control) : b_type_dbg_e'('x);

    always_comb begin
        rf_we       = 0;
        branch      = 0;
        jal         = 0;
        jalr        = 0;
        alusrc_sel  = 0;
        alu_control = 0;
        rfsrc_sel   = 3'b0;
        mem_mode    = 3'b0;
        dwe         = 0;
        case (opcode)
            `R_TYPE: begin
                rf_we       = 1'b1;
                branch      = 0;
                jal         = 0;
                jalr        = 0;
                alusrc_sel  = 1'b0;
                alu_control = {funct7[5], funct3};
                rfsrc_sel   = 3'b0;
                mem_mode    = 3'b0;
                dwe         = 0;  // don't care = 0으로 처리
            end
            `S_TYPE: begin
                rf_we = 1'b0;  // 데이터 레지스터에 다시 저장 X
                branch = 0;
                jal = 0;
                jalr = 0;
                alusrc_sel = 1'b1;  // rs1 + imm
                alu_control = `ADD;
                rfsrc_sel = 0;
                mem_mode = funct3;  // 나중에 사용하기 위함
                dwe = 1;
            end
            `IL_TYPE: begin
                rf_we       = 1'b1;
                branch      = 0;
                jal         = 0;
                jalr        = 0;
                alusrc_sel  = 1'b1;  // rs1 + imm
                alu_control = `ADD;
                rfsrc_sel   = 3'b001;  // from data memory
                mem_mode    = funct3;  // 나중에 사용하기 위함
                dwe         = 0;  // 메모리에 write 하면 안됨
            end
            `I_TYPE: begin  // imm 0~4까지 가져와서써라(shamt), 그 위는 r_type처럼 윗 비트 가져와서 명령어 분리하는데 사용해도 가능
                rf_we      = 1'b1;
                branch     = 0;
                jal        = 0;
                jalr       = 0;
                alusrc_sel = 1'b1;  // rs1 + imm
                if (funct3 == 3'b101) begin
                    alu_control = {funct7[5], funct3};
                end else begin
                    alu_control = {1'b0, funct3};
                end
                rfsrc_sel = 0;  // alu result
                mem_mode  = 0;  // don't care
                dwe       = 0;  // 메모리에 write 하면 안됨
            end
            `B_TYPE: begin
                rf_we       = 1'b0;  // register file에 저장 x
                branch      = 1;
                jal         = 0;
                jalr        = 0;
                alusrc_sel  = 1'b0;  // RS1, RS2 비교
                alu_control = {1'b0, funct3};
                rfsrc_sel   = 0;  // alu result
                mem_mode    = 0;
                dwe         = 0;  // 메모리에 write 하면 안됨
            end
            `UL_TYPE, `UA_TYPE: begin
                rf_we       = 1'b1;  // register file에 저장
                branch      = 0;
                jal         = 0;
                jalr        = 0;
                alusrc_sel  = 1'b0;
                alu_control = 4'b0000;
                if (opcode == `UL_TYPE) begin
                    rfsrc_sel = 3'b010;
                end else rfsrc_sel = 3'b011;
                mem_mode = 0;
                dwe      = 0;  // 메모리에 write 하면 안됨
            end
            `J_TYPE, `JL_TYPE: begin
                rf_we  = 1'b1;  // register file에 저장 x
                branch = 0;
                jal    = 1;
                if (opcode == `J_TYPE) begin
                    jalr = 0;
                end else begin  // JL type
                    jalr = 1;
                end
                alusrc_sel  = 1'b0;  // RS1, RS2 비교
                alu_control = 4'b0000;
                rfsrc_sel   = 3'b100;
                mem_mode    = 0;
                dwe         = 0;  // 메모리에 write 하면 안됨
            end
        endcase
    end
endmodule
