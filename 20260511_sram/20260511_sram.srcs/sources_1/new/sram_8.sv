`timescale 1ns / 1ps

module sram_8 (
    input  logic       clk,
    input  logic [7:0] addr,
    input  logic [7:0] wdata,
    input  logic       we,
    output logic [7:0] rdata
);
    logic [7:0] register[0:255];

    always_ff @(posedge clk) begin
        if (we) begin
            register[addr] <= wdata;
        end
    end

    assign rdata = register[addr];

endmodule
