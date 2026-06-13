`timescale 1ns / 1ps

module dedicated_cpu (
    input        clk,
    input        rst,
    output [7:0] out
);

    logic rf_src_sel;
    logic we;
    logic [1:0] ra0;
    logic [1:0] ra1;
    logic [1:0] wa;
    logic lt10;
    logic [7:0] wd;
    logic [7:0] rd0;
    logic [7:0] rd1;

    datapath U_DATA_PATH (.*);

    control_unit U_CONTROL_UNIT (.*);


endmodule

module datapath (
    input  logic       clk,
    input  logic       rst,
    input  logic       rf_src_sel,
    input  logic       we,
    input  logic [1:0] ra0,
    input  logic [1:0] ra1,
    input  logic [1:0] wa,
    output logic       lt10,
    output logic [7:0] out
);
    logic [7:0] alu_result, rf_src_mux_out;
    logic [7:0] r_rd0, r_rd1;

    assign out = r_rd1;

    mux_2x1 U_RFSRC_MUX_2X1 (
        .in0(8'h01),
        .in1(alu_result),
        .sel(rf_src_sel),
        .out_mux(rf_src_mux_out)
    );

    alu U_ALU (
        .a(r_rd0),
        .b(r_rd1),
        .out_alu(alu_result)
    );

    comparator U_COMP_LT10 (
        .in(r_rd0),
        .compare(8'h10),
        .comp_out(lt10)
    );

    register U_REGISTER (
        .*,
        .we (we),
        .wd (rf_src_mux_out),
        .ra0(ra0),
        .ra1(ra1),
        .wa (wa),
        .rd0(r_rd0),
        .rd1(r_rd1)
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
    input  logic       we,
    input  logic [7:0] wd,
    input  logic [1:0] ra0,
    input  logic [1:0] ra1,
    input  logic [1:0] wa,
    output logic [7:0] rd0,
    output logic [7:0] rd1
);
    logic [7:0] r[0:3];

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            r[0] <= 0;
            r[1] <= 0;
            r[2] <= 0;
            r[3] <= 0;

        end else begin
            if (we) begin
                r[wa] <= wd;
            end
        end
    end

    always_comb begin
        rd0 = r[ra0];
        rd1 = r[ra1];
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
    input logic clk,
    input logic rst,
    input logic lt10,  //ag10
    output logic rf_src_sel,
    output logic [1:0] ra0,
    output logic [1:0] ra1,
    output logic [1:0] wa,
    output logic we
    //output logic [7:0] out
);

    typedef enum {
        S0 = 0,  // a = 0
        S1,      // sum = 0
        S2,      // load(1)
        S3,      // while(a<10)
        S4,      // out = sum
        S5,      // a = a + 1
        S6,      // sum = sum + a  
        S7       // halt
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
        n_state    = c_state;
        rf_src_sel = 0;
        we         = 0;
        ra0        = 2'b00;
        ra1        = 2'b00;
        wa         = 2'b00;


        case (c_state)
            S0: begin
                // a = 0
                rf_src_sel = 1;
                we         = 1;
                ra0        = 2'b00;
                ra1        = 2'b00;
                wa         = 2'b11;
                n_state    = S1;
            end

            S1: begin
                // sum = 0
                rf_src_sel = 1;
                we         = 1;
                ra0        = 2'b00;
                ra1        = 2'b00;
                wa         = 2'b10;
                n_state    = S2;
            end

            S2: begin
                // r1 = 1
                rf_src_sel = 0;
                we         = 1;
                ra0        = 2'b00;
                ra1        = 2'b00;
                wa         = 2'b01;
                n_state    = S3;
            end

            S3: begin
                // while (a<10)
                rf_src_sel = 0;
                we         = 0;
                ra0        = 2'b11;
                ra1        = 2'b00;
                wa         = 2'b00;
                if (!lt10) begin
                    n_state = S4;
                end else begin
                    n_state = S7;
                end
            end

            S4: begin
                // out = sum
                rf_src_sel = 0;
                we         = 0;
                ra0        = 2'b10;
                ra1        = 2'b00;
                wa         = 2'b00;
                n_state    = S5;
            end

            S5: begin
                // a = a + 1
                rf_src_sel = 1;
                we         = 1;
                ra0        = 2'b11;
                ra1        = 2'b01;
                wa         = 2'b11;
                n_state    = S6;
            end

            S6: begin
                // sum = sum + a
                rf_src_sel = 1;
                we         = 1;
                ra0        = 2'b10;
                ra1        = 2'b11;
                wa         = 2'b10;
                n_state    = S3;
            end

            S7: begin
                // halt
                rf_src_sel = 0;
                we         = 0;
                ra0        = 2'b10;
                ra1        = 2'b00;
                wa         = 2'b00;
            end

        endcase
    end

endmodule
