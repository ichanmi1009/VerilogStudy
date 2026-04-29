`timescale 1ns / 1ps

module tb_uart_loopback ();

    parameter BAUD_DELAY = 2000;  //10us 한틱 정도 빨라짐 너무 빨라져서 2000n로 수정
    parameter BAUD_PERIOD = (100_000_000 / 9600) * 10 - BAUD_DELAY;  //한클럭 10n, 빠르게 하려고 - 뒤에 추가

    reg [7:0] compare_data;

    reg clk, rst, rx;
    wire tx;

    uart_loopback dut (
        .clk(clk),
        .rst(rst),
        .rx (rx),
        .tx (tx)
    );

    always #5 clk = ~clk;

    integer i;

    task SENDER_UART(
        input [7:0] send_data
    );  // 시간값을 만들어 넣을 수 있음
        begin
            // pc tx
            // start
            rx = 0;
            // start bit
            #(BAUD_PERIOD);
            // data bit
            for (i = 0; i < 8; i = i + 1) begin
                // rx, send_data[0] ~ [7]
                rx = send_data[i];
                #(BAUD_PERIOD);
            end
            // stop
            rx = 1;
            #(BAUD_PERIOD);
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        rx = 1;  // 초기값 start 1
        compare_data = 8'h30;  // ascii '0'
        @(negedge clk);
        @(negedge clk);

        rst = 0;
        SENDER_UART(compare_data);
        SENDER_UART(compare_data);
        SENDER_UART(compare_data);
        SENDER_UART(compare_data);
        SENDER_UART(compare_data);
        SENDER_UART(compare_data);
        SENDER_UART(compare_data);
        SENDER_UART(compare_data);
        SENDER_UART(compare_data);
        SENDER_UART(compare_data);
        SENDER_UART(compare_data);

        #(BAUD_PERIOD * 10);
        #1000;
        $stop;

    end


endmodule
