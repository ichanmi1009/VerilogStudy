`timescale 1ns / 1ps

module top #(
    parameter DIV_COUNT = 50_000,
    MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5,
    UT_WIDTH = 9,
    DH_WIDTH = 8
) (

    input clk,
    input rst,
    input [3:0] sw,
    input btn_R,
    input btn_L,
    input btn_U,
    input btn_D,
    input echo,
    output [8:0] led,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output trig,
    inout dht11
);

    wire [3:0] w_timer_btn, w_ultra_btn, w_dht_btn;
    wire [MSEC_WIDTH -1:0] w_msec;
    wire [ SEC_WIDTH -1:0] w_sec;
    wire [ MIN_WIDTH -1:0] w_min;
    wire [HOUR_WIDTH -1:0] w_hour;
    wire [  UT_WIDTH -1:0] w_ut;
    wire [  DH_WIDTH -1:0] w_hm;
    wire [  DH_WIDTH -1:0] w_tm;

    wire [7:0] w_msec_digit, w_sec_digit, w_min_digit, w_hour_digit;
    wire [15:0] w_ut_digit;
    wire [7:0] w_hm_digit, w_tm_digit;
    wire [1:0] w_c_mode;

    wire [2:0] w_timer_sw;
    wire [1:0] w_fnd_sel;

    wire w_btn_R, w_btn_L, w_btn_U, w_btn_D;

    button_debounce U_BTN_R (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_R),
        .o_btn(w_btn_R)
    );

    button_debounce U_BTN_L (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_L),
        .o_btn(w_btn_L)
    );

    button_debounce U_BTN_U (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_U),
        .o_btn(w_btn_U)
    );

    button_debounce U_BTN_D (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_D),
        .o_btn(w_btn_D)
    );

    system_control_unit U_SYSTEM_CONTROL_UNIT (

        .i_status_req(),
        .sw          (sw),
        .btn_R       (w_btn_R),
        .btn_L       (w_btn_L),
        .btn_U       (w_btn_U),
        .btn_D       (w_btn_D),
        .c_mode      (w_c_mode),
        .timer_sw    (w_timer_sw),
        .timer_btn   (w_timer_btn),
        .ultra_btn   (w_ultra_btn),
        .dht_btn     (w_dht_btn),
        .fnd_sel     (w_fnd_sel)

    );


    top_stopwatch_watch #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH (SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) U_STOPWATCH_WATCH (
        .clk     (clk),
        .rst     (rst),
        .btnR    (w_timer_btn[0]),
        .btnL    (w_timer_btn[1]),
        .btnU    (w_timer_btn[2]),
        .btnD    (w_timer_btn[3]),
        .timer_sw(w_timer_sw[2:0]),
        //sw[0] : 0: msec_sec,  1:min_hour , sw[1] : 0:stopwatch, 1:watch, sw[2]: 0:wt_runmode , 1:wt_setmod()e
        .led     (led[7:0]),
        .msec    (w_msec),
        .sec     (w_sec),
        .min     (w_min),
        .hour    (w_hour)
    );

    dht11 U_DHT11 (
        .clk  (clk),
        .rst  (rst),
        .dht_btn(w_dht_btn),
        .led  (led[8]),
        .hm   (w_hm),
        .tm   (w_tm),
        .dht11(dht11)
    );

    sr04 U_SR04 (
        .clk      (clk),
        .rst      (rst),
        .ultra_btn(w_ultra_btn),
        .echo     (echo),
        .trig     (trig),
        .distance (w_ut)
    );

    digit #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH (SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH),
        .UT_WIDTH  (UT_WIDTH),
        .DH_WIDTH  (DH_WIDTH)
    ) U_DIGIT (
        .msec      (w_msec),
        .sec       (w_sec),
        .min       (w_min),
        .hour      (w_hour),
        .ut        (w_ut),
        .hm        (w_hm),
        .tm        (w_tm),
        .msec_digit(w_msec_digit),
        .sec_digit (w_sec_digit),
        .min_digit (w_min_digit),
        .hour_digit(w_hour_digit),
        .ut_digit  (w_ut_digit),
        .hm_digit  (w_hm_digit),
        .tm_digit  (w_tm_digit)
    );

    fnd_controller #(
        .DIV_COUNT (DIV_COUNT),
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH (SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH),
        .UT_WIDTH  (UT_WIDTH),
        .DH_WIDTH  (DH_WIDTH)
    ) U_FND_CNTL (
        .clk(clk),
        .rst(rst),
        .timer_sw(w_timer_sw[0]),  // 0: msec_sec, 1:min_hour
        .fnd_sel(w_fnd_sel),
        .msec_digit(w_msec_digit),
        .sec_digit(w_sec_digit),
        .min_digit(w_min_digit),
        .hour_digit(w_hour_digit),
        .ut_digit(w_ut_digit),
        .hm_digit(w_hm_digit),
        .tm_digit(w_tm_digit),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

    selected_digit_mux U_SELECTED_DIGIT_MUX (
        .i_current_mode(w_c_mode),
        .msec_digit(w_msec_digit),
        .sec_digit(w_sec_digit),
        .min_digit(w_min_digit),
        .hour_digit(w_hour_digit),
        .ut_digit(w_ut_digit),
        .hm_digit(w_hm_digit),
        .tm_digit(w_tm_digit),
        .o_selected_digit_bus()
    );



endmodule
