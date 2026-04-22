`timescale 1ns / 1ps

module watch_control_unit (
    input clk,
    input rst,
    input i_up,
    input i_down,
    input i_right,
    input i_left,
    input [2:0] sw,
    output reg o_up,
    output reg o_down,
    output reg o_right,
    output reg o_left,
    output [2:0] o_led
);

    parameter [2:0] READY = 0, UP = 1, DOWN = 2, RIGHT = 3, LEFT = 4;
    reg [2:0] c_state, n_state;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= READY;
        end else begin
            c_state <= n_state;
        end
    end


    always @(*) begin
        n_state = c_state;
        o_up = 0;
        o_down = 0;
        o_right = 0;
        o_left = 0;

        case (c_state)
            READY: begin
                if (sw[2]) begin
                    if (i_up) n_state = UP;
                    else if (i_down) n_state = DOWN;
                    else if (i_right) n_state = RIGHT;
                    else if (i_left) n_state = LEFT;
                end
            end

            UP: begin
                o_up = 1;
                n_state = READY;
            end
            DOWN: begin
                o_down  = 1;
                n_state = READY;
            end
            RIGHT: begin
                o_right = 1;
                n_state = READY;
            end
            LEFT: begin
                o_left  = 1;
                n_state = READY;
            end
        endcase

    end

endmodule
