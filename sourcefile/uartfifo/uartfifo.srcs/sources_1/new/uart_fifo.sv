`timescale 1ns / 1ps

module uart_fifo (
    input  logic clk,
    input  logic rst,
    input  logic rx,
    output logic tx
);

    logic [7:0] w_rx_data, w_rx_pop_data, w_tx_pop_data, w_tx_busy;
    logic w_rx_done, w_rx_pop_empty, w_tx_push_full, w_tx_pop_empty;

    uart_sv U_UART_TOP (
        .*,
        .tx_start(~w_tx_pop_empty),
        .tx_data (w_tx_pop_data),
        .rx      (rx),
        .rx_data (w_rx_data),
        .rx_done (w_rx_done),
        .tx_busy (w_tx_busy),
        .tx      (tx)
    );

    fifo_sv U_FIFO_RX (
        .*,
        .push_data(w_rx_data),
        .push     (w_rx_done),
        .pop      (~w_tx_push_full),
        .pop_data (w_rx_pop_data),
        .full     (),
        .empty    (w_rx_pop_empty)
    );

    fifo_sv U_FIFO_TX (
        .clk      (clk),
        .rst      (rst),
        .push_data(w_rx_pop_data),
        .push     (~w_rx_pop_empty),
        .pop      (~w_tx_busy),
        .pop_data (w_tx_pop_data),
        .full     (w_tx_push_full),
        .empty    (w_tx_pop_empty)
    );

endmodule
