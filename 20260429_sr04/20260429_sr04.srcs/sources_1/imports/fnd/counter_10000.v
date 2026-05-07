`timescale 1ns / 1ps

module counter_10000 #(
    parameter DB_COUNT    = 1000,
    parameter TICK_COUNT  = 10_000_000,
    parameter FND_DIV_CNT = 50_000
)(
    input               clk,
    input               rst,
    input               BTN_D,
    input               BTN_L,
    input               BTN_R,
    output  [3:0]       fnd_com,
    output  [7:0]       fnd_data
);

    wire [13:0] w_tick_counter;
    wire [2:0]  w_mode;
    wire        o_mode, o_clear, o_run_stop;
    wire        w_btnR, w_btnL, w_btnD;

    assign w_mode = {o_mode, o_clear, o_run_stop};

    button_debounce #(
        .F_COUNT(DB_COUNT)
    ) u_BD_RUNSTOP(
        .clk   (clk),
        .rst   (rst),
        .i_btn (BTN_R),
        .o_btn (w_btnR)
    );

    button_debounce #(
        .F_COUNT(DB_COUNT)
    ) u_BD_MODE(
        .clk   (clk),
        .rst   (rst),
        .i_btn (BTN_D),
        .o_btn (w_btnD)
    );

    button_debounce #(
        .F_COUNT(DB_COUNT)
    ) u_BD_CLEAR(
        .clk   (clk),
        .rst   (rst),
        .i_btn (BTN_L),
        .o_btn (w_btnL)
    );

fnd_controller #(
    .DIV_COUNT(FND_DIV_CNT)
) uFnd_cnt(
    .clk      (clk),
    .rst      (rst),
    .fnd_in   (w_tick_counter),
    .fnd_com  (fnd_com),
    .fnd_data (fnd_data)
);

    control_unit uCNTL_unit(
        .clk        (clk),
        .rst        (rst),
        .i_mode     (w_btnD),
        .i_clear    (w_btnL),
        .i_run_stop (w_btnR),
        .o_mode     (o_mode),
        .o_clear    (o_clear),
        .o_run_stop (o_run_stop)
    );

    datapath #(
        .TICK_COUNT(TICK_COUNT)
    ) uDatapath(
        .clk          (clk),
        .rst          (rst),
        .i_mode       (w_mode),
        .tick_counter (w_tick_counter)
    );

endmodule