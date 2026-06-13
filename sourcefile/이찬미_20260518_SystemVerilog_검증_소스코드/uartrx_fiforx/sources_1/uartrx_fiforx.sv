`timescale 1ns / 1ps

module UARTRX_FIFORX (
    input clk,
    input rst,
    input rx,
    input pop,
    output [7:0] pop_data,
    output full,
    output empty
);
    logic [7:0] w_rx_data;
    logic w_rx_done, w_b_tick;

    uart_rx_sv U_UART_RX (
        .*,
        .b_tick(w_b_tick),
        .rx(rx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );

    fifo_sv U_FIFO_RX (
        .*,
        .push_data(w_rx_data),
        .push(w_rx_done),
        .pop(pop),
        .pop_data(pop_data),
        .full(full),
        .empty(empty)
    );

    baud_tick_gen U_BAUD_TICK_GEN (
        .*,
        .o_b_tick(w_b_tick)
    );
endmodule

module baud_tick_gen (
    input      clk,
    input      rst,
    output reg o_b_tick
);
    parameter F_COUNT = 100_000_000 / (9600 * 16); 
    parameter WIDTH = $clog2(F_COUNT) - 1;

    reg [WIDTH:0] counter_reg; 

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_b_tick    <= 0 ; 
        end else begin
            // period 9600 hz
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                o_b_tick <= 1'b1;
            end else begin
                o_b_tick <= 1'b0;
            end
        end
    end

endmodule
