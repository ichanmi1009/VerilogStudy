module fnd_controller #(
    parameter DIV_COUNT = 50_000
) (
    input         clk,
    input         rst,
    input  [13:0] fnd_in,
    output [ 3:0] fnd_com,
    output [ 7:0] fnd_data
);
    wire [3:0] w_out_mux;
    wire [3:0] w_digit_1;
    wire [3:0] w_digit_10;
    wire [3:0] w_digit_100;
    wire [3:0] w_digit_1000;
    wire [1:0] w_digit_sel;
    wire       w_1khz;

    digit_splitter uDigit_Spl (
        .digit_in  (fnd_in),
        .digit_1   (w_digit_1),
        .digit_10  (w_digit_10),
        .digit_100 (w_digit_100),
        .digit_1000(w_digit_1000)
    );

    mux_4x1 uMux41_0 (
        .in0    (w_digit_1),
        .in1    (w_digit_10),
        .in2    (w_digit_100),
        .in3    (w_digit_1000),
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
