`timescale 1ns / 1ps

module top_stopwatch_watch (
    input clk,
    input rst,
    input btnR,
    input btnL,
    input btnU,
    input btnD,
    input [3:0] sw,
    output [7:0] fnd_data,
    output [3:0] fnd_com,
    output [2:0] led
);
    parameter MSEC_WIDTH = 7, SEC_WIDTH = 6, MIN_WIDTH = 6, HOUR_WIDTH = 5;

    // 스톱워치, 워치용 전선
    wire [MSEC_WIDTH-1:0] st_msec, wt_msec;
    wire [SEC_WIDTH-1:0] st_sec, wt_sec;
    wire [MIN_WIDTH-1:0] st_min, wt_min;
    wire [HOUR_WIDTH-1:0] st_hour, wt_hour;

    wire [MSEC_WIDTH-1:0] out_msec;
    wire [ SEC_WIDTH-1:0] out_sec;
    wire [ MIN_WIDTH-1:0] out_min;
    wire [HOUR_WIDTH-1:0] out_hour;


    wire w_runstop, w_clear, w_mode;  // 스톱워치 기능
    wire w_up, w_down, w_right, w_left;  // 워치 기능
    wire w_btnR, w_btnL, w_btnD, w_btnU;  // 디바운스 거친 버튼

    assign out_msec = (sw[1] == 0) ? st_msec : wt_msec;
    assign out_sec  = (sw[1] == 0) ? st_sec : wt_sec;
    assign out_min  = (sw[1] == 0) ? st_min : wt_min;
    assign out_hour = (sw[1] == 0) ? st_hour : wt_hour;

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
        .i_save(w_btnU),
        .o_save(w_save),
        .o_view_mode(w_view_mode),
        .sw(sw),
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
        .i_save(w_save),
        .i_view_mode(w_view_mode),
        .msec(st_msec),
        .sec(st_sec),
        .min(st_min),
        .hour(st_hour)
    );

    watch_control_unit U_WATCH_CONTROL_UNIT (
        .clk(clk),
        .rst(rst),
        .i_up(w_btnU),
        .i_down(w_btnD),
        .i_right(w_btnR),
        .i_left(w_btnL),
        .sw(sw[1]),
        .o_up(w_up),
        .o_down(w_down),
        .o_right(w_right),
        .o_left(w_left),
        .o_led(led)
    );

    watch_datapath U_WATCH_DATAPATH (
        .clk(clk),
        .rst(rst),
        .i_up(w_up),
        .i_down(w_down),
        .i_left(w_left),
        .i_right(w_right),
        .msec(wt_msec),
        .sec(wt_sec),
        .min(wt_min),
        .hour(wt_hour)
    );


    fnd_controller U_FND_CNTL (
        .clk     (clk),
        .rst     (rst),
        .sw      (sw[0]),     // sw[0] : 0 msec, sec / 1 min,hour
        .msec    (out_msec),
        .sec     (out_sec),
        .min     (out_min),
        .hour    (out_hour),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );

endmodule
