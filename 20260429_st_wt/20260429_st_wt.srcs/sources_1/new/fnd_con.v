`timescale 1ns / 1ps
module fnd_controller #(
    parameter DIV_COUNT = 50_000,
    MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5,
    UT_WIDTH = 9,
    DH_WIDTH = 8
) (
    input         clk,
    input         rst,
    input         timer_sw,    // 0: msec_sec, 1:min_hour
    input  [ 1:0] fnd_sel,
    input  [ 7:0] msec_digit,
    input  [ 7:0] sec_digit,
    input  [ 7:0] min_digit,
    input  [ 7:0] hour_digit,
    input  [15:0] ut_digit,
    input  [ 7:0] hm_digit,
    input  [ 7:0] tm_digit,
    output [ 3:0] fnd_com,
    output [ 7:0] fnd_data
);
    wire [3:0] w_out_mux,w_out_mux_msec_sec,w_out_mux_min_hour,w_dot0,w_dot1,w_out_mux_ut,w_out_mux_dh,w_out_mux_st_wt;
    wire [3:0] w_msec_digit_1, w_msec_digit_10;
    wire [3:0] w_sec_digit_1, w_sec_digit_10;
    wire [3:0] w_min_digit_1, w_min_digit_10;
    wire [3:0] w_hour_digit_1, w_hour_digit_10;
    wire [3:0] w_ut_digit_1, w_ut_digit_10, w_ut_digit_100, w_ut_digit_1000;
    wire [3:0] w_hm_digit_1, w_hm_digit_10, w_tm_digit_1, w_tm_digit_10;

    assign w_msec_digit_1 = msec_digit[3:0];
    assign w_msec_digit_10 = msec_digit[7:4];
    assign w_sec_digit_1 = sec_digit[3:0];
    assign w_sec_digit_10 = sec_digit[7:4];
    assign w_min_digit_1 = min_digit[3:0];
    assign w_min_digit_10 = min_digit[7:4];
    assign w_hour_digit_1 = hour_digit[3:0];
    assign w_hour_digit_10 = hour_digit[7:4];
    assign w_ut_digit_1 = ut_digit[3:0];
    assign w_ut_digit_10 = ut_digit[7:4];
    assign w_ut_digit_100 = ut_digit[11:8];
    assign w_ut_digit_1000 = ut_digit[15:12];
    assign w_hm_digit_1 = hm_digit[3:0];
    assign w_hm_digit_10 = hm_digit[7:4];
    assign w_tm_digit_1 = tm_digit[3:0];
    assign w_tm_digit_10 = tm_digit[7:4];


    wire [2:0] w_digit_sel;
    wire       w_1khz;
    wire       dot;

    mux_4x1 uMUX_ut (
        .in0(w_ut_digit_1),     //digit 1
        .in1(w_ut_digit_10),     //digit 10  
        .in2(w_ut_digit_100),     //digit 100
        .in3(w_ut_digit_1000),     //digit 1000
        .sel(w_digit_sel[1:0]),     //to select input
        .out_mux(w_out_mux_ut)
    );

    mux_4x1 uMUX_dh (
        .in0(w_tm_digit_1),     //digit 1
        .in1(w_tm_digit_10),     //digit 10  
        .in2(w_hm_digit_1),     //digit 100
        .in3(w_hm_digit_10),     //digit 1000
        .sel(w_digit_sel[1:0]),     //to select input
        .out_mux(w_out_mux_dh)
    );

    mux_3x1 uMUX_ST_WT_UT_DH (
        .in0(w_out_mux_st_wt),
        .in1(w_out_mux_ut),
        .in2(w_out_mux_dh),
        .sel(fnd_sel),
        .out_mux(w_out_mux)
    );

    assign w_dot0 = 4'hF;
    assign w_dot1 = {3'b111, dot};

    mux_8x1 uMux_MSEC_SEC (
        .in0    (w_msec_digit_1),     // digit 1
        .in1    (w_msec_digit_10),    // digit 10
        .in2    (w_sec_digit_1),      // digit 1
        .in3    (w_sec_digit_10),     // digit 10
        .in4    (w_dot0),             // digit 1
        .in5    (w_dot0),             // digit 10
        .in6    (w_dot1),             // digit 100 : dot display
        .in7    (w_dot0),             // digit 1000
        .sel    (w_digit_sel),        // to select input
        .out_mux(w_out_mux_msec_sec)
    );

    mux_8x1 uMux_MIN_HOUR (
        .in0    (w_min_digit_1),      // digit 1
        .in1    (w_min_digit_10),     // digit 10
        .in2    (w_hour_digit_1),     // digit 1
        .in3    (w_hour_digit_10),    // digit 10
        .in4    (w_dot0),             // digit 1
        .in5    (w_dot0),             // digit 10
        .in6    (w_dot1),             // digit 100 :  dot display
        .in7    (w_dot0),             // digit 1000
        .sel    (w_digit_sel),        // to select input
        .out_mux(w_out_mux_min_hour)
    );

    //    mux_8x1 uMux_MUH (
    //        .in0    (w_msec_digit_1),     // digit 1
    //        .in1    (w_msec_digit_10),    // digit 10
    //        .in2    (w_sec_digit_100),    // digit 1
    //        .in3    (w_sec_digit_1000),   // digit 10
    //        .sel    (w_digit_sel[1:0]),   // to select input
    //        .out_mux(w_out_mux_msec_sec)
    //    );
    //
    //    mux_8x1 uMux_MDH (
    //        .in0    (w_msec_digit_1),     // digit 1
    //        .in1    (w_msec_digit_10),    // digit 10
    //        .in2    (w_sec_digit_100),    // digit 100
    //        .in3    (w_sec_digit_1000),   // digit 1000
    //        .sel    (w_digit_sel[1:0]),   // to select input
    //        .out_mux(w_out_mux_msec_sec)
    //    );
    //

    //MS,S / M,H SELECT
    mux_2x1 uMux_2x1 (
        .in0    (w_out_mux_msec_sec),
        .in1    (w_out_mux_min_hour),
        .sel    (timer_sw),
        .out_mux(w_out_mux_st_wt)
    );


    bcd uBcd0 (
        .bin     (w_out_mux),
        .bcd_data(fnd_data)
    );

    clk_div_1khz #(
        .DIV_COUNT(DIV_COUNT)
    ) uClk_div_1kHz (
        .clk   (clk),
        .rst   (rst),
        .o_1khz(w_1khz)
    );

    counter_8 uCNT8 (
        .clk      (w_1khz),
        .rst      (rst),
        .digit_sel(w_digit_sel)
    );

    decoder_2x4 uDec2x4 (
        .decoder_in(w_digit_sel[1:0]),
        .fnd_com   (fnd_com)
    );

    comparator uCOMP_dot (
        .comp_in  (msec_digit),
        .dot_onoff(dot)
    );


endmodule

module mux_2x1 (
    input  [3:0] in0,
    input  [3:0] in1,
    input        sel,
    output [3:0] out_mux
);
    assign out_mux = (sel) ? in1 : in0;  // in0: msec_sec , in1: min_hour

endmodule

module mux_8x1 (
    input  [3:0] in0,     //digit 1
    input  [3:0] in1,     //digit 10  
    input  [3:0] in2,     //digit 100
    input  [3:0] in3,     //digit 1000
    input  [3:0] in4,     //digit 1
    input  [3:0] in5,     //digit 10  
    input  [3:0] in6,     //digit 100
    input  [3:0] in7,     //digit 1000
    input  [2:0] sel,     //to select input
    output [3:0] out_mux
);
    reg [3:0] out_reg;
    assign out_mux = out_reg;

    //mux, (*) all input : sensitivity list
    always @(*) begin
        case (sel)
            3'b000:  out_reg = in0;
            3'b001:  out_reg = in1;
            3'b010:  out_reg = in2;
            3'b011:  out_reg = in3;
            3'b100:  out_reg = in4;
            3'b101:  out_reg = in5;
            3'b110:  out_reg = in6;
            3'b111:  out_reg = in7;
            default: out_reg = 4'b0000;  // 4'b0000 
        endcase
    end

endmodule

module mux_3x1 (
    input  [3:0] in0,
    input  [3:0] in1,
    input  [3:0] in2,
    input  [1:0] sel,
    output [3:0] out_mux
);
    reg [3:0] out_reg;
    assign out_mux = out_reg;
    always @(*) begin
        case (sel)
            2'b00:   out_reg = in0;
            2'b01:   out_reg = in1;
            2'b10:   out_reg = in2;
            default: out_reg = 4'bxxxx;  // 4'b0000 
        endcase
    end

endmodule

module mux_4x1 (
    input  [3:0] in0,     //digit 1
    input  [3:0] in1,     //digit 10  
    input  [3:0] in2,     //digit 100
    input  [3:0] in3,     //digit 1000
    input  [1:0] sel,     //to select input
    output [3:0] out_mux
);
    reg [3:0] out_reg;
    assign out_mux = out_reg;
    //mux, (*) all input : sensitivity list
    always @(*) begin
        case (sel)
            2'b00:   out_reg = in0;
            2'b01:   out_reg = in1;
            2'b10:   out_reg = in2;
            2'b11:   out_reg = in3;
            default: out_reg = 4'bxxxx;  // 4'b0000 
        endcase
    end
endmodule

module bcd (
    input      [3:0] bin,
    output reg [7:0] bcd_data
);

    always @(bin) begin
        case (bin)
            4'b0000: bcd_data = 8'hC0;  //0
            4'b0001: bcd_data = 8'hF9;
            4'b0010: bcd_data = 8'hA4;
            4'b0011: bcd_data = 8'hB0;  //3
            4'b0100: bcd_data = 8'h99;
            4'b0101: bcd_data = 8'h92;
            4'b0110: bcd_data = 8'h82;
            4'b0111: bcd_data = 8'hF8;
            4'b1000: bcd_data = 8'h80;
            4'b1001: bcd_data = 8'h90;
            4'b1010: bcd_data = 8'h88;  //A
            4'b1011: bcd_data = 8'h83;
            4'b1100: bcd_data = 8'hC6;
            4'b1101: bcd_data = 8'hA1;
            4'b1110: bcd_data = 8'h7F;  // dot on
            4'b1111: bcd_data = 8'hFF;  // dot off 
            default: bcd_data = 8'hFF;  //off
        endcase
    end


endmodule


module clk_div_1khz #(
    parameter DIV_COUNT = 50_000
) (
    input  clk,
    input  rst,
    output o_1khz
);

    reg [$clog2(DIV_COUNT):0] counter_reg;
    reg o_1khz_reg;

    assign o_1khz = o_1khz_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_1khz_reg  <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1'b1;
            if (counter_reg == (DIV_COUNT - 1)) begin
                counter_reg <= 0;
                o_1khz_reg  <= ~o_1khz_reg;
            end
        end
    end

endmodule

module counter_8 (
    input        clk,
    input        rst,
    output [2:0] digit_sel
);
    reg [2:0] counter_reg;

    assign digit_sel = counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 3'b000;
        end else begin
            counter_reg <= counter_reg + 1'b1;
        end
    end


endmodule

module decoder_2x4 (
    input      [1:0] decoder_in,
    output reg [3:0] fnd_com
);

    always @(*) begin
        case (decoder_in)
            2'b00:   fnd_com = 4'b1110;
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end
endmodule

module comparator (
    input  [7:0] comp_in,
    output       dot_onoff
);
    //0-49 : FALSE 0, 50-99 : TRUE 1    
    assign dot_onoff = (comp_in > 50);

endmodule
