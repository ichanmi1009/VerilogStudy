`timescale 1ns / 1ps

module uart_sv (
    input logic clk,
    input logic rst,
    input logic tx_start,
    input logic [7:0] tx_data,
    input logic rx,
    output logic [7:0] rx_data,
    output logic rx_done,
    output logic tx_busy,
    output logic tx
);

    wire w_b_tick;

    uart_rx_sv U_UART_RX (
        .clk    (clk),
        .rst    (rst),
        .b_tick (w_b_tick),
        .rx     (rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    uart_tx_sv U_UART_TX (
        .clk     (clk),
        .rst     (rst),
        .tx_start(tx_start),  // start trigger
        .tx_data (tx_data),
        .b_tick  (w_b_tick),
        .tx_busy (tx_busy),
        .tx      (tx)
    );

    baud_tick_gen U_BAUD_TICK_GEN (
        .clk     (clk),
        .rst     (rst),
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
