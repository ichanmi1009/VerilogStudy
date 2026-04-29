`timescale 1ns / 1ps

module uart_fifo_loopback (
    input  clk,
    input  rst,
    input  rx,
    output tx
);

    wire [7:0] w_rx_data, w_rx_pop_data, w_tx_pop_data, w_tx_busy;
    wire w_rx_done, w_rx_pop_empty, w_tx_push_full, w_tx_pop_empty;

    uart U_UART_TOP (
        .clk     (clk),
        .rst     (rst),
        .tx_start(~w_tx_pop_empty),
        // start trigger 후에 버튼 디바운스 회로 추가
        .tx_data (w_tx_pop_data),
        .rx      (rx),
        .rx_data (w_rx_data),
        .rx_done (w_rx_done),
        .tx_busy (w_tx_busy),
        .tx      (tx)
    );

    fifo U_FIFO_RX (
        .clk      (clk),
        .rst      (rst),
        .push_data(w_rx_data),
        .push     (w_rx_done),
        .pop      (~w_tx_push_full),
        .pop_data (w_rx_pop_data),
        .full     (),
        .empty    (w_rx_pop_empty)
    );

    fifo U_FIFO_TX (
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
