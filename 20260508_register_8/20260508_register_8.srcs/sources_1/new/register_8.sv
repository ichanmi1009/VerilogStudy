`timescale 1ns / 1ps

module register_8 (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] d,
    output logic [7:0] q
);

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            q <= 0;
        end else begin
            q <= d;
        end
    end

endmodule
