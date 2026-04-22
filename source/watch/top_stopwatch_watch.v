`timescale 1ns / 1ps

module top_stopwatch_watch (
    input clk,
    input rst,
    input btnR,
    input btnL,
    input btnU,
    input btnD,
    input [2:0] sw,
    output [7:0] fnd_data,
    output [3:0] fnd_com,
    output [2:0] led
);
    parameter MSEC_WIDTH = 7, SEC_WIDTH = 6, MIN_WIDTH = 6, HOUR_WIDTH = 5;


    wire [MSEC_WIDTH-1:0] w_msec;
    wire [ SEC_WIDTH-1:0] w_sec;
    wire [ MIN_WIDTH-1:0] w_min;
    wire [HOUR_WIDTH-1:0] w_hour;
    wire w_runstop, w_clear, w_mode;
    wire w_btnR, w_btnL, w_btnD, w_btnU;
    assign led = sw;

    button_debounce U_BTNR (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnR),
        .o_btn(w_btnR)
    );

    button_debounce U_BTNL (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnL),
        .o_btn(w_btnL)
    );

    button_debounce U_BTND (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnD),
        .o_btn(w_btnD)
    );

    button_debounce U_BTNU (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnU),
        .o_btn(w_btnU)
    );

    stopwatch_control_unit U_STOPWATCH_CONTROL_UNIT (
        .clk(clk),
        .rst(rst),
        .i_mode(w_btnD),
        .i_clear(w_btnL),
        .i_run_stop(w_btnR),
        .i_btnu(w_btnU),
        .o_mode(w_mode),
        .o_clear(w_clear),
        .o_run_stop(w_run_stop)
    );


    stopwatch_datapath U_STOPWATCH_DATATPATH (
        .clk(clk),
        .rst(rst),
        .i_runstop(w_run_stop),
        .i_clear(w_clear),
        .i_mode(w_mode),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour)
    );



    fnd_controller U_FND_CNTL (
        .clk     (clk),
        .rst     (rst),
        .sw      (sw[0]),    // sw[0] : 0 msec, sec / 1 min,hour
        .msec    (w_msec),
        .sec     (w_sec),
        .min     (w_min),
        .hour    (w_hour),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );

endmodule
