module fnd_controller_sensor #(
    parameter DIV_COUNT = 50_000,
    DH_WIDTH = 8
) (
    input                  clk,
    input                  rst,
    // input                  fnd_sel,
    input  [DH_WIDTH -1:0] hm,
    input  [DH_WIDTH -1:0] tm,
    // input  [         13:0] fnd_in,
    output [          3:0] fnd_com,
    output [          7:0] fnd_data
);
    wire [3:0] w_out_mux;
    wire [3:0] w_hm_digit_1, w_hm_digit_10, w_tm_digit_1, w_tm_digit_10;
    wire [1:0] w_digit_sel;
    wire       w_1khz;

    digit_splitter U_DH_HM_Digit_Spl (
        .digit_in(hm),
        .digit_1 (w_hm_digit_1),
        .digit_10(w_hm_digit_10)
    );

    digit_splitter U_DH_TM_Digit_Spl (
        .digit_in(tm),
        .digit_1 (w_tm_digit_1),
        .digit_10(w_tm_digit_10)
    );

    mux_4x1 U_MUX_4_1 (
        .in0    (w_tm_digit_1),
        .in1    (w_tm_digit_10),
        .in2    (w_hm_digit_1),
        .in3    (w_hm_digit_10),
        .sel    (w_digit_sel),
        .out_mux(w_out_mux)
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

    counter_4 uCNT4 (
        .clk      (w_1khz),
        .rst      (rst),
        .digit_sel(w_digit_sel)
    );

    decoder_2x4 uDec2x4 (
        .decoder_in(w_digit_sel),
        .fnd_com   (fnd_com)
    );

endmodule

module digit_splitter (
    input  [7:0] digit_in,  //14bit
    output [3:0] digit_1,
    output [3:0] digit_10
);

    assign digit_1  = digit_in % 10;  //digit 1
    assign digit_10 = (digit_in / 10) % 10;  //digit 10

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
            4'b0001: bcd_data = 8'hF9;  //1           
            4'b0010: bcd_data = 8'hA4;  //2
            4'b0011: bcd_data = 8'hB0;  //3
            4'b0100: bcd_data = 8'h99;
            4'b0101: bcd_data = 8'h92;
            4'b0110: bcd_data = 8'h82;
            4'b0111: bcd_data = 8'hF8;
            4'b1000: bcd_data = 8'h80;
            4'b1001: bcd_data = 8'h90;  //9
            4'b1010: bcd_data = 8'h88;  //A
            4'b1011: bcd_data = 8'h83;  //B
            4'b1100: bcd_data = 8'hC6;  //C
            4'b1101: bcd_data = 8'hA1;  //D
            4'b1110: bcd_data = 8'h86;  //E
            4'b1111: bcd_data = 8'h8E;  //F
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

module counter_4 (
    input        clk,
    input        rst,
    output [1:0] digit_sel
);
    reg [1:0] counter_reg;

    assign digit_sel = counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 2'b00;
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
