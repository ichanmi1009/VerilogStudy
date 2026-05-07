`timescale 1ns / 1ps

module selected_digit_mux (
    input [1:0] i_current_mode,

    input [ 7:0] msec_digit,
    input [ 7:0] sec_digit,
    input [ 7:0] min_digit,
    input [ 7:0] hour_digit,
    input [15:0] ut_digit,
    input [ 7:0] hm_digit,
    input [ 7:0] tm_digit,

    output reg [31:0] o_selected_digit_bus
);

    localparam MODE_STW = 2'b00;
    localparam MODE_WTC = 2'b01;
    localparam MODE_ULT = 2'b10;
    localparam MODE_DHT = 2'b11;

    always @(*) begin
        o_selected_digit_bus = 32'd0;
        case (i_current_mode)
            MODE_STW, MODE_WTC: begin
                o_selected_digit_bus = {
                    hour_digit, min_digit, sec_digit, msec_digit
                };
            end
            // Pad with zeros to match the output bit width
            MODE_ULT: o_selected_digit_bus = {16'd0, ut_digit};
            MODE_DHT: o_selected_digit_bus = {16'd0, hm_digit, tm_digit};
        endcase
    end
endmodule
