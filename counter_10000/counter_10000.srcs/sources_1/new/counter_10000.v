`timescale 1ns / 1ps

module counter_10000 (
    input clk,
    input rst,
    input btnL,
    input btnR,
    input btnD,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);
    wire [13:0] w_tick_counter;
    wire w_run_stop, w_clear, w_mode;
    wire w_btnR, w_btnL, w_btnD;

    button_debounce U_BD_RUNSTOP (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnR),
        .o_btn(w_btnR)
    );

    button_debounce U_BD_CLEAR (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnL),
        .o_btn(w_btnL)
    );


    button_debounce U_BD_MODE (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnD),
        .o_btn(w_btnD)
    );


    control_unit U_CONTROL_UNIT (
        .clk(clk),
        .rst(rst),
        .i_mode(w_btnD),
        .i_run_stop(w_btnR),
        .i_clear(w_btnL),
        .o_mode(w_mode),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear)
    );

    datapath U_DATAPATH (
        .clk(clk),
        .rst(rst),
        .i_run_stop(w_run_stop),
        .i_clear(w_clear),
        .i_mode(w_mode),
        .tick_counter(w_tick_counter)
    );

    fnd_controller U_FND_CNTL (
        .clk(clk),
        .rst(rst),
        .fnd_in(w_tick_counter),  //input 14bit로 바뀜
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );


endmodule

module datapath (
    input clk,
    input rst,
    input i_run_stop,
    input i_clear,
    input i_mode,
    output [13:0] tick_counter
);

    tick_counter U_TICK_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick_10hz),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .o_tick_counter(tick_counter)
    );

    clk_tick_gen U_CLK_TICK_GEN (
        .clk(clk),
        .rst(rst),
        .i_run_stop(i_run_stop),
        .i_clear(i_clear),
        .o_tick(w_tick_10hz)
    );

endmodule

module tick_counter (
    input clk,
    input rst,
    input i_tick,
    input i_clear,
    input i_mode,
    output [13:0] o_tick_counter
);

    reg [$clog2(10_000)-1:0] tick_counter_reg;

    assign o_tick_counter = tick_counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst | i_clear) begin
            tick_counter_reg <= 14'd0;
        end else begin
            //else if (i_tick == 1'b1) begin// if(i_tick) begin 틱이 1인구간만 카운트 값 올리기 10ns

            if (i_tick) begin  // down count
                if (!i_mode) begin
                    tick_counter_reg <= tick_counter_reg + 1;
                    if (tick_counter_reg == (10_000 - 1)) begin
                        tick_counter_reg <= 14'd0;
                    end
                end else begin  //up count
                    tick_counter_reg <= tick_counter_reg - 1;
                    if (tick_counter_reg == (0)) begin
                        tick_counter_reg <= 9999;
                    end

                end
            end
        end
    end

endmodule

module clk_tick_gen (
    input clk,
    input rst,
    input i_run_stop,
    input i_clear,  //0415
    output reg o_tick  //tick 신호 1bit
);

    // 주파수 100_000_000(1초당 1억번) / 10hz (천만번 카운트) -1 : 100Mhz -> 10hz 
    // 천만을 표현할 수 있는 지수 10000000 log base 2 -> 이거를 clog2로 계산 , -1 해준이유 0까지라서
    reg [$clog2(100_000_000/10)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst | i_clear) begin
            counter_reg <= 24'd0;
            o_tick      <= 1'b0;
        end else begin
            if (i_run_stop) begin
                counter_reg <= counter_reg + 1;
                o_tick <= 1'b0;
                if (counter_reg == (10_000_000 - 1)) begin  //10_000_000 - 1 시뮬레이션으로 10_00사용
                    counter_reg <= 24'd0;
                    o_tick <= 1'b1;
                end
            end
        end
    end

endmodule
