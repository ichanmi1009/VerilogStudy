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

    wire [MSEC_WIDTH-1:0] st_msec, wt_msec, sel_msec;
    wire [SEC_WIDTH-1:0]  st_sec,  wt_sec,  sel_sec;
    wire [MIN_WIDTH-1:0]  st_min,  wt_min,  sel_min;
    wire [HOUR_WIDTH-1:0] st_hour, wt_hour, sel_hour;

    wire w_run_stop, w_clear, w_mode;
    wire w_save, w_view_mode;

    wire w_up, w_down, w_right, w_left;

    wire w_btnR, w_btnL, w_btnD, w_btnU;

    assign led[0] = sw[0];
    assign led[1] = sw[1];
    assign led[2] = (sw[1] && (wt_hour >= 12)) ? 1'b1 : 1'b0;  // 시계 모드일 때만 PM 표시

    mux_2sel #(
        .MSEC_WIDTH(MSEC_WIDTH), 
        .SEC_WIDTH(SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),  
        .HOUR_WIDTH(HOUR_WIDTH)
    ) U_MUX_2SEL (
        .i_st_msec(st_msec), 
        .i_st_sec(st_sec),
        .i_st_min (st_min),  
        .i_st_hour(st_hour),
        .i_wt_msec(wt_msec), 
        .i_wt_sec(wt_sec),
        .i_wt_min (wt_min),  
        .i_wt_hour(wt_hour),
        .sel      (sw[1]),
        .o_msec   (sel_msec), 
        .o_sec(sel_sec),
        .o_min    (sel_min),  
        .o_hour(sel_hour)
    );

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
        .clk      (clk),
        .rst      (rst),
        .i_mode   (w_btnD),
        .i_clear  (w_btnL),
        .i_run_stop(w_btnR),
        .i_save   (w_btnU),
        .o_save   (w_save),
        .o_view_mode(w_view_mode),
        .sw       (sw),
        .o_mode   (w_mode),
        .o_clear  (w_clear),
        .o_run_stop(w_run_stop)
    );

    stopwatch_datapath U_STOPWATCH_DATATPATH (
        .clk       (clk),
        .rst       (rst),
        .i_runstop (w_run_stop),
        .i_clear   (w_clear),
        .i_mode    (w_mode),
        .i_save    (w_save),
        .i_view_mode(w_view_mode),
        .msec      (st_msec),
        .sec       (st_sec),
        .min       (st_min),
        .hour      (st_hour)
    );

    watch_control_unit U_WATCH_CONTROL_UNIT (
        .clk    (clk),
        .rst    (rst),
        .i_up   (w_btnU),
        .i_down (w_btnD),
        .i_right(w_btnR),
        .i_left (w_btnL),
        .sw     (sw),
        .o_up   (w_up),
        .o_down (w_down),
        .o_right(w_right),
        .o_left (w_left)
    );

    watch_datapath U_WATCH_DATAPATH (
        .clk    (clk),
        .rst    (rst),
        .i_up   (w_up),
        .i_down (w_down),
        .i_left (w_left),
        .i_right(w_right),
        .sw     (sw),    
        .msec   (wt_msec),
        .sec    (wt_sec),
        .min    (wt_min),
        .hour   (wt_hour)
    );

    fnd_controller U_FND_CNTL (
        .clk     (clk),
        .rst     (rst),
        .sw      (sw),       // sw[0]: 0=msec/sec, 1=min/hour
        .msec    (sel_msec),
        .sec     (sel_sec),
        .min     (sel_min),
        .hour    (sel_hour),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );


endmodule

module mux_2sel #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH  = 6,
    MIN_WIDTH  = 6,
    HOUR_WIDTH = 5
) (
    input  [MSEC_WIDTH-1:0] i_st_msec,
    input  [ SEC_WIDTH-1:0] i_st_sec,
    input  [ MIN_WIDTH-1:0] i_st_min,
    input  [HOUR_WIDTH-1:0] i_st_hour,
    input  [MSEC_WIDTH-1:0] i_wt_msec,
    input  [ SEC_WIDTH-1:0] i_wt_sec,
    input  [ MIN_WIDTH-1:0] i_wt_min,
    input  [HOUR_WIDTH-1:0] i_wt_hour,
    input                   sel,
    output [MSEC_WIDTH-1:0] o_msec,
    output [ SEC_WIDTH-1:0] o_sec,
    output [ MIN_WIDTH-1:0] o_min,
    output [HOUR_WIDTH-1:0] o_hour
);
    assign o_msec = sel ? i_wt_msec : i_st_msec;
    assign o_sec  = sel ? i_wt_sec  : i_st_sec;
    assign o_min  = sel ? i_wt_min  : i_st_min;
    assign o_hour = sel ? i_wt_hour : i_st_hour;
endmodule