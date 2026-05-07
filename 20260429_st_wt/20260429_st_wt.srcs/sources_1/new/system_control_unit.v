`timescale 1ns / 1ps

module system_control_unit (

    input i_status_req,
    input [3:0] sw,
    input btn_R,
    input btn_L,
    input btn_U,
    input btn_D,

    output [1:0] c_mode,

    output [2:0] timer_sw,

    output [3:0] timer_btn,
    output [3:0] ultra_btn,
    output [3:0] dht_btn,

    output [1:0] fnd_sel

);

    wire w_watch_en;
    wire w_stopwatch_en;
    wire w_timer_en;
    wire w_ultra_en;
    wire w_dht_en;


    main_mode_decoder u_main_mode_decoder (
        .main_mode(sw[1:0]),
        .i_status_req(i_status_req),
        .watch_en(w_watch_en),
        .stopwatch_en(w_stopwatch_en),
        .timer_en(w_timer_en),
        .ultra_en(w_ultra_en),
        .dht_en(w_dht_en),
        .c_mode(c_mode)
    );


    timer_switch_generator u_timer_switch_generator (
        .watch_en(w_watch_en),
        .stopwatch_en(w_stopwatch_en),
        .display_mode(sw[2]),
        .control_mode(sw[3]),
        .timer_sw(timer_sw)
    );


    button_router u_button_router (
        .btn_pulse({btn_D, btn_U, btn_L, btn_R}),
        .timer_en(w_timer_en),
        .ultra_en(w_ultra_en),
        .dht_en(w_dht_en),

        .timer_btn(timer_btn),
        .ultra_btn(ultra_btn),
        .dht_btn  (dht_btn)
    );

    fnd_sel u_fnd_sel (
        .timer_en(w_timer_en),
        .ultra_en(w_ultra_en),
        .dht_en  (w_dht_en),
        .fnd_sel (fnd_sel)
    );

endmodule

module main_mode_decoder (

    input [1:0] main_mode,
    input i_status_req,  //pc로 부터 입력이 들어오면 1인것임 

    output reg watch_en, //enable 신호는 fpga로 부터, 그리고 arbiter를 거쳐 pc에서 올 수도 있음 
    output reg stopwatch_en,
    output reg timer_en,
    output reg ultra_en,
    output reg dht_en,
    output [1:0] c_mode  //sender의 input. 

);

    reg [1:0] inter_c_mode;


    always @(*) begin

        watch_en = 0;
        stopwatch_en = 0;
        timer_en = 0;
        ultra_en = 0;
        dht_en = 0;
        inter_c_mode = 2'b00;

        case (main_mode)
            2'b00: watch_en = 1;
            2'b01: stopwatch_en = 1;
            2'b10: ultra_en = 1;
            2'b11: dht_en = 1;
        endcase

        if (watch_en || stopwatch_en) timer_en = 1;

        //c_mode = //상태를 센더한테 보내조야함         
        case (1'b1)
            watch_en: inter_c_mode = 2'b00;
            stopwatch_en: inter_c_mode = 2'b01;
            ultra_en: inter_c_mode = 2'b10;
            dht_en: inter_c_mode = 2'b11;
        endcase

    end
    assign c_mode = i_status_req ? inter_c_mode : 2'b00;



endmodule

module timer_switch_generator (
    input watch_en,
    input stopwatch_en,
    input display_mode,
    input control_mode,
    output [2:0] timer_sw
);

    assign timer_sw[0] = display_mode;
    assign timer_sw[1] = (watch_en || ~stopwatch_en);
    assign timer_sw[2] = control_mode;


endmodule


module button_router (
    input [3:0] btn_pulse,
    input timer_en,
    input ultra_en,
    input dht_en,

    output [3:0] timer_btn,
    output [3:0] ultra_btn,
    output [3:0] dht_btn
);

    assign timer_btn = timer_en ? btn_pulse : 4'b0000;
    assign ultra_btn = ultra_en ? btn_pulse : 4'b0000;
    assign dht_btn   = dht_en ? btn_pulse : 4'b0000;

endmodule


module fnd_sel (
    input timer_en,
    input ultra_en,
    input dht_en,
    output reg [1:0] fnd_sel
);

    always @(*) begin
        case (1'b1)
            timer_en: fnd_sel = 2'b00;
            ultra_en: fnd_sel = 2'b01;
            dht_en:   fnd_sel = 2'b10;
            default:  fnd_sel = 2'bzz;
        endcase
    end

endmodule
