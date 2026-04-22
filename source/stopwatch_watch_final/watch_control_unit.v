`timescale 1ns / 1ps


module watch_control_unit (
    input       clk,
    input       rst,
    input       i_up,
    input       i_down,
    input       i_right,
    input       i_left,
    input [3:0] sw, // sw[2]=1 이면 워치 조작 모드
    output reg  o_up,
    output reg  o_down,
    output reg  o_right,
    output reg  o_left
);

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            o_up    <= 1'b0;
            o_down  <= 1'b0;
            o_right <= 1'b0;
            o_left  <= 1'b0;
        end else begin
            o_up    <= 1'b0;
            o_down  <= 1'b0;
            o_right <= 1'b0;
            o_left  <= 1'b0;

            if (sw[2]) begin
                if (i_up) begin
                    o_up    <= 1'b1;
                end else if (i_down) begin
                    o_down  <= 1'b1;
                end else if (i_right) begin
                    o_right <= 1'b1;
                end else if (i_left) begin  
                    o_left  <= 1'b1;
                end
            end
        end
    end

endmodule