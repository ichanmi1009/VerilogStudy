`timescale 1ns / 1ps
////////////////////////////////////////////


module top_stopwatch_watch(
    input               clk     ,
    input               rst     ,
    input               btnR    ,
    input               btnL    ,
    input               btnU    ,
    input               btuD    ,
    input   [2:0]       sw      , //sw[0] : 0: msec_sec,  1:min_hour , sw[1] : 0:stopwatch, 1:watch, sw[2]: 0:wt_runmode , 1:wt_setmode
    output  [3:0]       fnd_com ,
    output  [7:0]       fnd_data,
    output  [7:0]       led         //led0 : st or wt display // led1 : msec,sec or min hour display // led2 : watch run mode display // led3 : watch setup mode
    //led4 : min1 cursor(LD10) //led5 : min10 cursor(LD11) //led6 : sec1,hour cursor(LD12) //led7 : sec10 cursor(LD13)
);
    parameter MSEC_WIDTH = 7, 
              SEC_WIDTH  = 6, 
              MIN_WIDTH  = 6, 
              HOUR_WIDTH = 5 ;

wire [MSEC_WIDTH - 1:0] w_msec_sw;
wire [SEC_WIDTH  - 1:0] w_sec_sw;
wire [MIN_WIDTH  - 1:0] w_min_sw;
wire [HOUR_WIDTH - 1:0] w_hour_sw;

wire [MSEC_WIDTH - 1:0] w_msec_wt;
wire [SEC_WIDTH  - 1:0] w_sec_wt;
wire [MIN_WIDTH  - 1:0] w_min_wt;
wire [HOUR_WIDTH - 1:0] w_hour_wt;

wire [MSEC_WIDTH - 1:0] w_msec;
wire [SEC_WIDTH  - 1:0] w_sec;
wire [MIN_WIDTH  - 1:0] w_min;
wire [HOUR_WIDTH - 1:0] w_hour;

wire [6:0] w_msec11_wt;
wire [3:0] w_sec1_wt;
wire [2:0] w_sec10_wt;
wire [3:0] w_min1_wt;
wire [2:0] w_min10_wt;
wire [4:0] w_hour11_wt;

wire w_runstop, w_clear, w_mode;
wire w_set_mode,  w_digit_sel; 
wire [1:0]  w_time_sel, w_edit_cmd;
wire w_btnR, w_btnL, w_btnD, w_btnU;

wire [23:0]   w_SW_data, w_WT_data;
wire [23:0]   w_mux_out;


button_debounce UBTNR(
    .clk(clk),
    .rst(rst),
    .i_btn(btnR),
    .o_btn(w_btnR)
);

button_debounce UBTNL(
    .clk(clk),
    .rst(rst),
    .i_btn(btnL),
    .o_btn(w_btnL)
);

button_debounce UBTNU(
    .clk(clk),
    .rst(rst),
    .i_btn(btnU),
    .o_btn(w_btnU)
);

button_debounce UBTND(
    .clk(clk),
    .rst(rst),
    .i_btn(btuD),
    .o_btn(w_btnD)
);

assign led[0] = sw[0]; //sw[0] == 0 : msec_sec display, sw[0] == 1 : min_hour display

top_control_unit uCONTROL_UNIT(
    .clk        (clk)           ,
    .rst        (rst)           ,
    .sw         (sw[2:1])       ,
    .btnD       (w_btnD)        ,
    .btnL       (w_btnL)        ,
    .btnR       (w_btnR)        ,
    .btnU       (w_btnU)        ,
    .o_mode     (w_mode)        , 
    .o_clear    (w_clear)       , 
    .o_runstop  (w_runstop)     ,
    .o_set_mode (w_set_mode)    ,
    .o_timesel  (w_time_sel)    ,
    .o_digitsel (w_digit_sel)   ,
    .o_edit     (w_edit_cmd)    ,
    .led        (led[7:1])
);

 stopwatch_datapath U_STOPWATCH_DATAPATH(
    .clk         (clk),
    .rst         (rst),
    .i_runstop   (w_runstop),
    .i_clear     (w_clear),
    .i_mode      (w_mode),   
    .msec        (w_msec_sw),
    . sec        (w_sec_sw),    
    . min        (w_min_sw),
    .hour        (w_hour_sw)
);


watch_datapath U_WATCH_DATAPATH(
    .clk        (clk)        ,
    .rst        (rst)        ,
    .i_set_mode (w_set_mode) , //  0 : runmode : clockRUN,1 : setmode: clockSTOP
    .i_digit_sel(w_digit_sel),// 0: digit 10, 1: digit 1
    .i_time_sel (w_time_sel) , // 00: hour, 01: min, 10 : sec
    .i_edit_cmd (w_edit_cmd) , //01:up, 10:down, default:00
    .msec       (w_msec11_wt),
    .sec_d1     (w_sec1_wt)  ,    
    .sec_d10    (w_sec10_wt) ,    
    .min_d1     (w_min1_wt)  ,
    .min_d10    (w_min10_wt) ,
    .hour       (w_hour11_wt) 
);    

watch_fnd_adapter U_FND_ADAPTER (
    .i_hour    (w_hour11_wt),
    .i_min_d10 (w_min10_wt),
    .i_min_d1  (w_min1_wt),
    .i_sec_d10 (w_sec10_wt),
    .i_sec_d1  (w_sec1_wt),
    .i_msec    (w_msec11_wt),
    .hour      (w_hour_wt),
    .min       (w_min_wt),
    .sec       (w_sec_wt),
    .msec      (w_msec_wt)
);


assign w_SW_data = {w_hour_sw, w_min_sw, w_sec_sw, w_msec_sw};
assign w_WT_data = {w_hour_wt,w_min_wt,w_sec_wt,w_msec_wt};


mux_2x1_nbit #(
    .WIDTH(24)
)U_MUX2X1(
    .in0(w_SW_data),
    .in1(w_WT_data),
    .sel(sw[1]),
    .y  (w_mux_out) 
);

    assign  w_msec  = w_mux_out[6:0];
    assign  w_sec   = w_mux_out[12:7];
    assign  w_min   = w_mux_out[18:13];
    assign  w_hour  = w_mux_out[23:19];


fnd_controller uFND_CNTL(
    .clk        (clk),
    .rst        (rst),
    .sw         (sw[0]), // sw[0], 0: msec_sec, 1:min_hour
    .msec       (w_msec),
    .sec        (w_sec),    
    .min        (w_min),
    .hour       (w_hour),
    .fnd_com    (fnd_com),
    .fnd_data   (fnd_data)
);


endmodule
