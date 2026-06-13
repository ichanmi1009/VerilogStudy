`timescale 1ns / 1ps
`include "define.vh"

module datapath (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    input  logic        rf_we,
    input  logic [ 3:0] alu_control,
    output logic [31:0] instr_addr
);
    logic [31:0] rd1, rd0, alu_result;

    register_file U_REG_FILE (
        .clk(clk),
        .raddr0(instr_code[19:15]),
        .raddr1(instr_code[24:20]),
        .rf_we(rf_we),
        .waddr(instr_code[11:7]),
        .wdata(alu_result),
        .rdata0(rd0),
        .rdata1(rd1)
    );

    alu U_ALU (
        .alu_control(alu_control),
        .a(rd0),  // rs1
        .b(rd1),  // rs2
        .alu_result(alu_result)  // rd
    );

    program_counter U_PC (
        .clk(clk),
        .rst(rst),
        .pc_in(instr_addr),  // for next program count
        .pc_out(instr_addr)  // count program
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

module alu (
    input  logic [ 3:0] alu_control,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] alu_result
);
    always_comb begin
        alu_result = 32'd0;
        case (alu_control)
            `ADD:  alu_result = a + b;
            `SUB:  alu_result = a - b;
            `SLL:  alu_result = a << b;
            `SLT:  alu_result = $signed(a) < $signed(b) ? 1 : 0;
            `SLTU: alu_result = (a < b) ? 1 : 0;
            `XOR:  alu_result = a ^ b;
            `SRL:  alu_result = a >> b;
            `SRA:  alu_result = $signed(a) >>> b;
            `OR:   alu_result = a | b;
            `AND:  alu_result = a & b;
        endcase
    end

endmodule


module register_file (
    input  logic        clk,
    input  logic [ 4:0] raddr0,
    input  logic [ 4:0] raddr1,
    input  logic        rf_we,   // register file write enable
    input  logic [ 4:0] waddr,   // 왜 4?
    input  logic [31:0] wdata,
    output logic [31:0] rdata0,
    output logic [31:0] rdata1
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

    assign rdata0 = (raddr0 != 0) ? register_file[raddr0] : 32'd0;
    assign rdata1 = (raddr1 != 0) ? register_file[raddr1] : 32'd0;

endmodule
