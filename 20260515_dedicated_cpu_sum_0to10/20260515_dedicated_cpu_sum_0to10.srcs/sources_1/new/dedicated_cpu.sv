`timescale 1ns / 1ps

module dedicated_cpu (
    input        clk,
    input        rst,
    output [7:0] out
);

    logic ag10;
    logic asrc_sel;
    logic sumsrc_sel;
    logic areg_load;
    logic sumreg_load;
    logic outreg_load;
    logic alusrc_sel;

    datapath U_DATA_PATH (.*);

    control_unit U_CONTROL_UNIT (.*);


endmodule

module datapath (
    input        clk,
    input        rst,
    input        asrc_sel,
    input        sumsrc_sel,
    input        areg_load,
    input        sumreg_load,
    input        outreg_load,
    input        alusrc_sel,
    output       ag10,
    output [7:0] out
);
    logic [7:0]
        areg_out_mux,
        sumreg_out_mux,
        areg_out,
        sumreg_out,
        w_alu,
        alusrc_mux_out;

    mux_2x1 U_ASRC_MUX_2X1 (
        .in0(8'h00),
        .in1(w_alu),
        .sel(asrc_sel),
        .out_mux(areg_out_mux)
    );

    mux_2x1 U_SUMSRC_MUX_2X1 (
        .in0(8'h00),
        .in1(w_alu),
        .sel(sumsrc_sel),
        .out_mux(sumreg_out_mux)
    );

    register U_A_REG (
        .*,
        .load(areg_load),
        .data_in(areg_out_mux),
        .data_out(areg_out)
    );

    register U_SUM_REG (
        .*,
        .load(sumreg_load),
        .data_in(sumreg_out_mux),
        .data_out(sumreg_out)
    );

    mux_2x1 U_ALUSRC_MUX_2X1 (
        .in0(8'h01),
        .in1(sumreg_out),
        .sel(alusrc_sel),
        .out_mux(alusrc_mux_out)
    );

    alu U_ALU (
        .a(areg_out),
        .b(alusrc_mux_out),
        .out_alu(w_alu)
    );

    comparator U_COMP_AG10 (
        .in(areg_out),
        .compare(8'h09),  // 이부분을 바꿔도 되는건가
        .comp_out(ag10)
    );

    register U_OUT_REG (
        .*,
        .load(outreg_load),
        .data_in(sumreg_out),
        .data_out(out)
    );


endmodule


module alu (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] out_alu
);

    assign out_alu = a + b;  // 캐리는 무시

endmodule

module comparator (
    input  [7:0] in,
    input  [7:0] compare,
    output       comp_out
);
    assign comp_out = (in > compare);
endmodule

module register (
    input  logic       clk,
    input  logic       rst,
    input  logic       load,
    input  logic [7:0] data_in,
    output logic [7:0] data_out
);
    logic [7:0] register;

    assign data_out = register;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register <= 0;
        end else begin
            if (load) begin
                register <= data_in;
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
    input  logic ag10,
    output logic asrc_sel,
    output logic sumsrc_sel,
    output logic areg_load,
    output logic sumreg_load,
    output logic outreg_load,
    output logic alusrc_sel
);

    typedef enum {
        S0 = 0,
        S1,
        S2,
        S3,
        S4,
        S5
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
        n_state = c_state;
        asrc_sel = 0;
        sumsrc_sel = 0;
        areg_load = 0;
        sumreg_load = 0;
        outreg_load = 0;
        alusrc_sel = 0;


        case (c_state)
            S0: begin
                // a = 0, sum = 0
                asrc_sel    = 0;
                sumsrc_sel  = 0;
                areg_load   = 1;
                sumreg_load = 1;
                outreg_load = 0;
                alusrc_sel  = 0;
                n_state     = S1;
            end

            S1: begin
                // a<10
                asrc_sel    = 0;
                sumsrc_sel  = 0;
                areg_load   = 0;
                sumreg_load = 0;
                outreg_load = 0;
                alusrc_sel  = 0;
                if (!ag10) begin
                    n_state = S2;
                end else begin
                    n_state = S5;
                end
            end

            S2: begin
                // out = sum
                asrc_sel    = 0;
                sumsrc_sel  = 0;
                areg_load   = 0;
                sumreg_load = 0;
                outreg_load = 1;
                alusrc_sel  = 0;
                n_state     = S3;
            end

            S3: begin
                // a = a + 1
                asrc_sel    = 1;
                sumsrc_sel  = 0;
                areg_load   = 1;
                sumreg_load = 0;
                outreg_load = 0;
                alusrc_sel  = 0;
                n_state     = S4;
            end

            S4: begin
                // sum = sum + a
                asrc_sel    = 0;
                sumsrc_sel  = 1;
                areg_load   = 0;
                sumreg_load = 1;
                outreg_load = 0;
                alusrc_sel  = 1;
                n_state     = S1;
            end

            S5: begin
                // halt
                asrc_sel    = 0;
                sumsrc_sel  = 0;
                areg_load   = 0;
                sumreg_load = 0;
                outreg_load = 1;
                alusrc_sel  = 0;
            end

        endcase
    end



endmodule


