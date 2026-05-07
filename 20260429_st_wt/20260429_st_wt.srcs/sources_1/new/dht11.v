`timescale 1ns / 1ps

module dht11 (
    input clk,
    input rst,
    input [3:0] dht_btn,
    output led,
    output [7:0] hm,
    output [7:0] tm,
    inout dht11
);
    wire w_tick_us, w_valid;
    assign led = w_valid;

    dht11_controller U_DHT11_CNTL (
        .clk        (clk),
        .rst        (rst),
        .dht11_start(dht_btn[0]),
        .tick_us    (w_tick_us),
        .humidity   (hm),
        .temperature(tm),
        .valid      (w_valid),     // for check sum valid가 1이면 led 킴
        .dht11      (dht11)
    );


    tick_gen_us_dht11 U_TICK_GEN_US (
        .clk(clk),
        .rst(rst),
        .tick_us(w_tick_us)
    );


endmodule

module dht11_controller (
    input        clk,
    input        rst,
    input        dht11_start,
    input        tick_us,
    output [7:0] humidity,
    output [7:0] temperature,
    output       valid,        // for check sum valid가 1이면 led 킴
    inout        dht11
);
    parameter IDLE = 0, START = 1, WAIT = 2, SYNCL = 3, SYNCH = 4;
    parameter DATA_SYNC = 5, DATA_COUNT = 6, DATA_DECISION = 7;
    parameter STOP = 8;

    reg [3:0] c_state, n_state;
    reg [5:0] bit_cnt_reg, bit_cnt_next;
    reg [$clog2(19_000)-1:0] tick_cnt_reg, tick_cnt_next;  // general tick count
    reg out_sel_reg, out_sel_next;  //dht11 io 3state control
    reg dht11_sync1, dht11_sync2, dht11_reg, dht11_next;  // dht11 output drive
    reg [39:0] data_reg, data_next;  //데이터 레지스터 40비트 추가
    reg [7:0]
        hm_reg, tm_reg;  // 깜빡거리는 문제 해결하기 위해 추가

    // dht output 3state control
    assign dht11 = (out_sel_reg) ? dht11_reg : 1'bz;

    assign valid = (c_state == STOP) && (data_reg[7:0] == (data_reg[39:32] + data_reg[31:24] + data_reg[23:16] + data_reg[15:8])) ? 1:0; // 체크SUM

    assign humidity = hm_reg;  //data_reg[39:32]
    assign temperature = tm_reg;  //data_reg[23:16]
    //checksum 조건문 걸어서 추가 필요
    //싱크로나이저 추가

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state      <= IDLE;
            bit_cnt_reg  <= 0;
            tick_cnt_reg <= 0;
            out_sel_reg  <= 1'b1;  // default output mode
            dht11_reg    <= 1'b1;  // default high state IDLE일때 1
            dht11_sync1  <= 1'b1;
            dht11_sync2  <= 1'b1;
            data_reg     <= 0;
            hm_reg       <= 0;  //깜빡거리는 문제 해결
            tm_reg       <= 0;

        end else begin
            c_state      <= n_state;
            bit_cnt_reg  <= bit_cnt_next;
            tick_cnt_reg <= tick_cnt_next;
            out_sel_reg  <= out_sel_next;  // when idle dht11 output mode
            dht11_reg    <= dht11_next;
            dht11_sync1  <= dht11;
            dht11_sync2  <= dht11_sync1;
            data_reg     <= data_next;  //check
            if (valid) begin
                hm_reg <= data_reg[39:32];
                tm_reg <= data_reg[23:16];
            end
        end
    end

    always @(*) begin
        n_state       = c_state;
        bit_cnt_next  = bit_cnt_reg;
        tick_cnt_next = tick_cnt_reg;
        out_sel_next  = out_sel_reg;
        dht11_next    = dht11_reg;
        data_next     = data_reg;
        case (c_state)
            IDLE: begin
                dht11_next   = 1'b1;
                out_sel_next = 1'b1;
                if (dht11_start) begin
                    bit_cnt_next  = 0;
                    tick_cnt_next = 0;
                    n_state       = START;
                end
            end
            START: begin
                dht11_next = 1'b0;
                if (tick_us) begin
                    if (tick_cnt_reg >= 19_000) begin  // 19000?19msec라서
                        tick_cnt_next = 0;
                        n_state = WAIT;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            WAIT: begin
                dht11_next = 1'b1;
                if (tick_us) begin
                    if (tick_cnt_reg >= 30) begin  // 
                        tick_cnt_next = 0;
                        n_state = SYNCL;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            SYNCL: begin
                // output is high impedance "z"
                out_sel_next = 1'b0;  // 출력 끊음
                if (tick_us) begin
                    if ((tick_cnt_reg > 40) && (dht11_sync2)) begin
                        tick_cnt_next = 0;
                        n_state = SYNCH;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            SYNCH: begin
                if (tick_us) begin
                    if ((tick_cnt_reg > 40) && (!dht11_sync2)) begin
                        tick_cnt_next = 0;
                        n_state = DATA_SYNC;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            DATA_SYNC: begin
                if (tick_us) begin
                    if (dht11_sync2) begin
                        tick_cnt_next = 0;
                        n_state = DATA_COUNT;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            DATA_COUNT: begin
                if (tick_us) begin
                    if (!dht11_sync2) begin
                        n_state = DATA_DECISION;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end

            end
            DATA_DECISION: begin
                if (tick_cnt_reg > 45) begin
                    data_next = {data_reg[38:0], 1'b1};
                    tick_cnt_next = 0;
                end else begin
                    data_next = {data_reg[38:0], 1'b0};
                    tick_cnt_next = 0;
                end
                bit_cnt_next = bit_cnt_reg + 1;

                if (bit_cnt_reg >= 39) begin
                    n_state = STOP;
                end else begin
                    n_state = DATA_SYNC;
                end
            end
            STOP: begin
                if (tick_us) begin
                    if (tick_cnt_reg >= 50) begin
                        tick_cnt_next = 0;
                        n_state = IDLE;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

        endcase

    end

endmodule



module tick_gen_us_dht11 (
    input      clk,
    input      rst,
    output reg tick_us
);

    parameter F_COUNT = 100_000_000 / 1_000_000;  //1us
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_us     <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_us     <= 1'b1;
            end else begin
                tick_us <= 1'b0;
            end
        end
    end

endmodule
