`timescale 1ns / 1ps

module dedicated_cpu (
    input        clk,
    input        rst,
    output [7:0] out
);

    logic asrc_sel;
    logic areg_load;
    logic out_sel;
    logic eq9;

    datapath U_DATA_PATH (.*);

    control_unit U_CONTROL_UNIT (.*);


endmodule

module datapath (
    input        clk,
    input        rst,
    input        asrc_sel,
    input        areg_load,
    input        out_sel,
    output       eq9,
    output [7:0] out
);
    logic [7:0] w_out_mux, w_data_out, w_alu;

    mux_2x1 U_MUX_2X1 (
        .in0(8'h00),
        .in1(w_alu),
        .sel(asrc_sel),
        .out_mux(w_out_mux)
    );

    a_reg U_A_REG (
        .*,
        .load(areg_load),
        .data_in(w_out_mux),
        .data_out(w_data_out)
    );

    alu U_ALU (
        .a(w_data_out),
        .b(8'h01),
        .out_alu(w_alu)
    );

    compare_eq9 U_EQ9 (
        .in(w_data_out),
        .compare(8'h09),  // 이부분을 바꿔도 되는건가
        .eq_9(eq9)
    );

    assign out = (out_sel) ? w_data_out : 8'hzz;

endmodule


module alu (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] out_alu
);

    assign out_alu = a + b;  // 캐리는 무시

endmodule

module compare_eq9 (
    input  [7:0] in,
    input  [7:0] compare,
    output       eq_9
);
    assign eq_9 = (in == compare);
endmodule

module a_reg (
    input  logic       clk,
    input  logic       rst,
    input  logic       load,
    input  logic [7:0] data_in,
    output logic [7:0] data_out
);
    logic [7:0] a_register;

    assign data_out = a_register;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            a_register <= 0;
        end else begin
            if (load) begin
                a_register <= data_in;
            end
        end
    end
endmodule

module mux_2x1 (
    input  logic [7:0] in0,
    input  logic [7:0] in1,
    input  logic       sel,
    output logic [7:0] out_mux
);

    always_comb begin
        case (sel)

            1'b0: begin
                out_mux = in0;
            end
            1'b1: begin
                out_mux = in1;
            end

        endcase
    end

endmodule


module control_unit (
    input  logic clk,
    input  logic rst,
    input  logic eq9,
    output logic asrc_sel,
    output logic areg_load,
    output logic out_sel
);

    typedef enum {
        S0 = 0,
        S1,
        S2
    } state_t;
    state_t c_state, n_state;

    // logic [1:0] c_state, n_state;
    // parameter s0 = 2'd0, s1 = 2'd1, s2 = 2'd2;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= S0;
        end else begin
            c_state <= n_state;
        end
    end

    always_comb begin
        n_state   = c_state;
        asrc_sel  = 0;
        areg_load = 0;
        out_sel   = 0;

        case (c_state)
            S0: begin
                asrc_sel  = 0;
                areg_load = 1;
                out_sel   = 0;
                n_state   = S1;
            end

            S1: begin
                if (eq9 == 1) begin
                    asrc_sel  = 0;
                    areg_load = 0;
                    out_sel   = 0;
                    n_state   = S2;
                end else begin
                    asrc_sel  = 1;
                    areg_load = 1;
                    out_sel   = 0;
                    n_state   = S1;
                end
            end

            S2: begin
                asrc_sel  = 0;
                areg_load = 0;
                out_sel   = 1;
            end

        endcase
    end



endmodule


