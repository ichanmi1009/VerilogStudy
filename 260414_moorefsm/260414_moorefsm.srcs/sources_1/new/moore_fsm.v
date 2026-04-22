`timescale 1ns / 1ps

module moore_fsm (
    input  clk,
    input  rst,
    input  din_bit,
    output dout_bit
);
    parameter [2:0] STATE_A = 3'b000, STATE_B = 3'b001, STATE_C = 3'b010;
    parameter [2:0] STATE_D = 3'b100, STATE_E = 3'b111;
    reg [2:0] state_reg, next_state;

    always @(*) begin
        case (state_reg)
            STATE_A:
            if (din_bit == 0) next_state = STATE_A;
            else if (din_bit == 1) next_state = STATE_B;
            else next_state = STATE_A;
            STATE_B:
            if (din_bit == 0) next_state = STATE_C;
            else if (din_bit == 1) next_state = STATE_B;
            else next_state = STATE_A;
            STATE_C:
            if (din_bit == 0) next_state = STATE_A;
            else if (din_bit == 1) next_state = STATE_D;
            else next_state = STATE_A;
            STATE_D:
            if (din_bit == 0) next_state = STATE_E;
            else if (din_bit == 1) next_state = STATE_B;
            else next_state = STATE_A;
            STATE_E:
            if (din_bit == 0) next_state = STATE_A;
            else if (din_bit == 1) next_state = STATE_B;
            else next_state = STATE_A;
            default: next_state = STATE_A;

        endcase
    end

    always @(posedge clk, posedge rst) begin
        if (rst == 1) state_reg <= STATE_A;
        else state_reg <= next_state;
    end

    assign dout_bit = (state_reg == STATE_E) ? 1 : 0;  // moore


endmodule
