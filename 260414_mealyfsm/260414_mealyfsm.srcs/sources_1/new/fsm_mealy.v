`timescale 1ns / 1ps

module mealy_fsm (
    input  clk,
    input  rst,
    input  din_bit,
    output dout_bit
);
    reg [2:0] state_reg, next_state;

    parameter [1:0] STATE_A = 2'b00, STATE_B = 2'b01, STATE_C = 2'b10, STATE_D = 2'b11;

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
            if (din_bit == 0) next_state = STATE_A;
            else if (din_bit == 1) next_state = STATE_B;
            else next_state = STATE_A;

        endcase
    end

    always @(posedge clk, posedge rst) begin
        if (rst == 1) state_reg <= STATE_A;
        else state_reg <= next_state;
    end

    assign dout_bit = (state_reg == STATE_D) && (din_bit == 0) ? 1 : 0;

endmodule
