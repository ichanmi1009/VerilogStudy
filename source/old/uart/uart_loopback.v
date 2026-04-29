`timescale 1ns / 1ps

module uart_loopback (
    input  clk,
    input  rst,
    input  rx,
    output tx
);

    wire [7:0] w_rx_data;
    wire w_tx_start;

    uart U_UART_TOP (
        .clk(clk),
        .rst(rst),
        .tx_start(w_tx_start),  // start trigger 후에 버튼 디바운스 회로 추가
        .tx_data(w_rx_data),
        .rx(rx),
        .rx_data(w_rx_data),
        .rx_done(w_tx_start),
        .tx_busy(),
        .tx(tx)
    );

endmodule
