`timescale 1ns / 1ps

module tb_uart ();

    //(system clock * 1clock time) / BAUD
    parameter UART_BAUD_PERIOD = (100_000_000 * 10 / 9600);

    reg clk, rst, btnR;
    reg [7:0] sw;
    wire tx;

    uart dut (
        .clk (clk),
        .rst (rst),
        .btnR(btnR),  // start trigger 후에 버튼 디바운스 회로 추가
        .sw  (sw),
        .tx  (tx)
    );

    always #5 clk = ~clk;

    initial begin
        clk  = 0;
        rst  = 1;
        btnR = 0;
        sw   = 8'h30;

        // rst
        @(negedge clk);
        @(negedge clk);  // 2클럭
        rst  = 0;

        // button push btnR
        // for tx start trigger
        btnR = 1;
        #(100_000); // 1000 Cycle x 8 시프트 레지스터 x 10 클럭의 개수
        btnR = 0;

        // 1bit
        repeat (10) #(UART_BAUD_PERIOD);

        btnR = 1;
        sw   = 8'h31;  // ascii '1'
        #(100_000); // 1000 Cycle x 8 시프트 레지스터 x 10 클럭의 개수
        btnR = 0;

        // 1bit
        repeat (10) #(UART_BAUD_PERIOD);

        #1000;
        $stop;

    end



endmodule
