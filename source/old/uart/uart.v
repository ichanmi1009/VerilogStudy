`timescale 1ns / 1ps

module uart (
    input clk,
    input rst,
    input tx_start,  // start trigger 후에 버튼 디바운스 회로 추가
    input [7:0] tx_data,
    input rx,
    output [7:0] rx_data,
    output rx_done,
    output tx_busy,
    output tx
);

    wire w_b_tick;

    uart_rx U_UART_RX (
        .clk    (clk),
        .rst    (rst),
        .b_tick (w_b_tick),
        .rx     (rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    uart_tx U_UART_TX (
        .clk     (clk),
        .rst     (rst),
        .tx_start(tx_start),  // start trigger
        .tx_data (tx_data),   // 30이 아스키 코드 0, 8'h30 ; asci 0
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

module uart_tx (
    input        clk,
    input        rst,
    input        tx_start,  // start trigger
    input  [7:0] tx_data,
    input        b_tick,
    output       tx,
    output       tx_busy
);

    parameter IDLE = 0, START = 1;
    parameter DATA = 2, STOP = 3;


    reg [2:0] c_state, n_state;
    reg tx_reg, tx_next;
    // tx data register
    reg [7:0] data_reg, data_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;  // bit count 추가
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg tx_busy_reg, tx_busy_next;

    assign tx = tx_reg;
    assign tx_busy = tx_busy_reg;

    // state register
    // current : output, next : input
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state        <= IDLE;
            tx_reg         <= 1'b1;
            data_reg       <= 8'h00;
            bit_cnt_reg    <= 3'b000;
            b_tick_cnt_reg <= 4'h0;
            tx_busy_reg    <= 1'b0;
        end else begin
            c_state        <= n_state;
            tx_reg         <= tx_next;
            data_reg       <= data_next;
            bit_cnt_reg    <= bit_cnt_next;
            b_tick_cnt_reg <= b_tick_cnt_next;
            tx_busy_reg    <= tx_busy_next;
        end
    end

    // next st CL, output
    always @(*) begin
        // current_state
        n_state         = c_state;  // n_state 초기화
        tx_next         = tx_reg;  // tx output
        data_next       = data_reg;
        bit_cnt_next    = bit_cnt_reg;
        b_tick_cnt_next = b_tick_cnt_reg;
        tx_busy_next    = tx_busy_reg;
        case (c_state)
            IDLE: begin  // 처음 reset을 IDLE로 지정
                tx_next      = 1'b1;
                tx_busy_next = 1'b0;
                if (tx_start) begin
                    tx_busy_next    = 1'b1; // 빨리 처리하려고 밀리처럼 출력
                    data_next = tx_data;
                    b_tick_cnt_next = 0;
                    n_state = START;
                end
            end

            START: begin
                tx_next = 1'b0;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        bit_cnt_next = 3'b000;  // 초기화
                        n_state = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            DATA: begin

                // tx_next = data_reg[bit_cnt_reg]; PIPO, parallel output
                // to output from bit0 of data_reg
                tx_next = data_reg[0];  // PISO, serial output
                // right shift 1bit data register

                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;

                        if (bit_cnt_reg == 7) begin
                            n_state = STOP;
                        end else begin
                            data_next = {
                                1'b0, data_reg[7:1]
                            };  // b_tick 밑에 있어도 되는데, bit 증가할때 shift 하고 싶어서 여기에 위치
                            bit_cnt_next = bit_cnt_reg + 1;
                            n_state = DATA;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            STOP: begin
                tx_next = 1;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        tx_busy_next = 1'b0;
                        n_state = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule


// baud tick 9600hz * 16 tick gen (tx, rx 에서 같은 tick_gen 받아와야함 교수님이 지정해준 규칙, 나중에 tx 바꾸려고 해서 그런듯 / 뭐 가능은 함)
module baud_tick_gen (
    input      clk,
    input      rst,
    output reg o_b_tick
);
    parameter F_COUNT = 100_000_000 / (9600 * 16); // 주파수를 16배 올릴거라서 * 16 : 651까지임
    parameter WIDTH = $clog2(F_COUNT) - 1;

    reg [WIDTH:0] counter_reg;  // counter 해줄 도구

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_b_tick    <= 0 ; // o_b_tick 바로 쓰려고 output reg o_b_tick 선언
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
