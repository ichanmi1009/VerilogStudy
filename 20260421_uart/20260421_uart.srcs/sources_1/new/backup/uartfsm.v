`timescale 1ns / 1ps

module uart (
    input clk,
    input rst,
    input btnR,  // start trigger 후에 버튼 디바운스 회로 추가
    input [7:0] sw,
    output tx
);

    wire w_start, w_b_tick;

    button_debounce U_BUTTON_DEBOUNCE (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnR),
        .o_btn(w_start)
    );

    baud_tick_gen U_BAUD_TICK_GEN (
        .clk     (clk),
        .rst     (rst),
        .o_b_tick(w_b_tick)
    );

    uart_tx U_UART_TX (
        .clk     (clk),
        .rst     (rst),
        .tx_start(w_start),   // start trigger
        .tx_data (sw),        // 30이 아스키 코드 0, 8'h30 ; asci 0
        .b_tick  (w_b_tick),
        .tx      (tx)
    );

endmodule

module uart_tx (
    input        clk,
    input        rst,
    input        tx_start,  // start trigger
    input  [7:0] tx_data,
    input        b_tick,
    output       tx
);

    parameter IDLE = 0, WAIT = 1, START = 2;
    parameter DATA_STATE = 3, STOP = 4;


    reg [3:0] c_state, n_state;
    reg tx_reg, tx_next;
    // tx data register
    reg [7:0] data_reg, data_next;
    reg [2:0] bit_count_reg, bit_count_next;

    assign tx = tx_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            tx_reg <= 1'b1;
            data_reg <= 8'h00;
            bit_count_reg <= 3'b000;
        end else begin
            c_state <= n_state;
            tx_reg <= tx_next;
            data_reg <= data_next;
            bit_count_reg <= bit_count_next;
        end
    end

    // next st CL, output
    always @(*) begin
        // current_state
        n_state = c_state;  // n_state 초기화
        tx_next = tx_reg;  // tx output
        data_next = data_reg;
        bit_count_next = bit_count_reg;
        case (c_state)
            IDLE: begin  // 처음 reset을 IDLE로 지정
                tx_next = 1;
                if (tx_start) begin
                    data_next = tx_data;
                    n_state   = WAIT;
                end
            end

            WAIT: begin
                if (b_tick) begin
                    n_state = START;
                end
            end

            START: begin
                tx_next = 0;
                if (b_tick) begin
                    n_state = DATA_STATE;
                end
            end

            DATA_STATE: begin
                tx_next = data_reg[0];
                if (b_tick) begin
                    data_next = {1'b0, data_reg[7:1]};
                    if (bit_count_reg == 7) begin
                        n_state = STOP;
                        bit_count_next = 0;
                    end else bit_count_next = bit_count_reg + 1;
                end
            end

            STOP: begin
                tx_next = 1;
                if (b_tick) begin
                    n_state = IDLE;
                end
            end
        endcase

        /*BIT0: begin
                tx_next = data_reg[0];
                if (b_tick) begin
                    n_state = BIT1;
                end
            end

            BIT1: begin
                tx_next = data_reg[1];
                if (b_tick) begin
                    n_state = BIT2;
                end
            end

            BIT2: begin
                tx_next = data_reg[2];
                if (b_tick) begin
                    n_state = BIT3;
                end
            end

            BIT3: begin
                tx_next = data_reg[3];
                if (b_tick) begin
                    n_state = BIT4;
                end
            end

            BIT4: begin
                tx_next = data_reg[4];
                if (b_tick) begin
                    n_state = BIT5;
                end
            end

            BIT5: begin
                tx_next = data_reg[5];
                if (b_tick) begin
                    n_state = BIT6;
                end
            end

            BIT6: begin
                tx_next = data_reg[6];
                if (b_tick) begin
                    n_state = BIT7;
                end
            end

            BIT7: begin
                tx_next = data_reg[7];
                if (b_tick) begin
                    n_state = STOP;
                end
            end
            */

    end
endmodule


// baud tick 9600hz tick gen
module baud_tick_gen (
    input      clk,
    input      rst,
    output reg o_b_tick
);
    parameter F_COUNT = 100_000_000 / 9600;
    parameter WIDTH = $clog2(F_COUNT) - 1;

    reg [WIDTH:0] counter_reg;  // counter 해줄 도구

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_b_tick <= 0 ; // o_b_tick 바로 쓰려고 output reg o_b_tick 선언
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
