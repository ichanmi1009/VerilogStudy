`timescale 1ns / 1ps

module uart_rx (

    input        clk,
    input        rst,
    input        b_tick,
    input        rx,
    output [7:0] rx_data,
    output       rx_done
);

    parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] c_state, n_state;
    reg [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [7:0] data_reg, data_next;  // 내부
    reg rx_done_reg, rx_done_next;
    reg rx_syn1, rx_syn2;


    assign rx_done = rx_done_reg;
    assign rx_data = data_reg;  // done 이후 읽기


    always @(posedge clk, posedge rst) begin // 매 상승엣지에 같은 타이밍에 처리하기 위함
        if (rst) begin
            c_state        <= IDLE;
            b_tick_cnt_reg <= 0;
            bit_cnt_reg    <= 0;
            data_reg       <= 8'h00;
            rx_done_reg    <= 1'b0;
        end else begin
            c_state        <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            data_reg       <= data_next;
            rx_done_reg    <= rx_done_next;
        end
    end

    // next, output CL
    always @(*) begin
        n_state = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next = bit_cnt_reg;
        data_next = data_reg;
        rx_done_next = rx_done_reg;
        case (c_state)
            IDLE: begin
                rx_done_next = 0;
                if (b_tick && (!rx)) begin  //!rx도 가능, &도 가능
                    b_tick_cnt_next = 0;
                    n_state         = START;
                end
            end
            START: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 7) begin // 싱크로나이저만 쓰면 상관없음
                        b_tick_cnt_next = 0;
                        bit_cnt_next    = 0;
                        n_state         = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        data_next = {rx, data_reg[7:1]};
                        b_tick_cnt_next = 0;
                        if (bit_cnt_reg == 7) begin
                            b_tick_cnt_next = 0;
                            bit_cnt_next = 0;  // 비트 카운트 초기화
                            n_state = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end


            STOP: begin
                if (b_tick) begin
                    if ((b_tick_cnt_reg == 23) || ((b_tick_cnt_reg > 16) && !rx)) begin // 8바이트 이상 입력 시 깨지는 현상 방지, 23->15로 변경, 오류 감지되어 23돌고, rx가 1이되면 idle 상태로
                        rx_done_next = 1'b1;
                        n_state = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

        endcase
    end


endmodule
