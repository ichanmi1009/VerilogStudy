`timescale 1ns / 1ps

module stopwatch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (

    input clk,
    input rst,
    input i_runstop,
    input i_clear,
    input i_mode,
    input i_save,
    input i_view_mode,

    output [MSEC_WIDTH - 1:0] msec,
    output [ SEC_WIDTH - 1:0] sec,
    output [ MIN_WIDTH - 1:0] min,
    output [HOUR_WIDTH - 1:0] hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    wire [MSEC_WIDTH - 1:0] w_real_msec;
    wire [ SEC_WIDTH - 1:0] w_real_sec;
    wire [ MIN_WIDTH - 1:0] w_real_min;
    wire [HOUR_WIDTH - 1:0] w_real_hour;


    save_time U_SAVE_TIME (
        .clk(clk),
        .rst(rst),
        .i_save(i_save),
        .i_clear(i_clear),
        .i_view_mode(i_view_mode),
        .i_real_msec(w_real_msec),
        .i_real_sec(w_real_sec),
        .i_real_min(w_real_min),
        .i_real_hour(w_real_hour),
        .o_msec(msec),
        .o_sec(sec),
        .o_min(min),
        .o_hour(hour)
    );



    //hour
    st_tick_counter #(
        .TIMES(24),
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_ST_HOUR_TICK_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_hour_tick),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .time_counter(w_real_hour),
        .o_tick()
    );

    //min
    st_tick_counter #(
        .TIMES(60),
        .BIT_WIDTH(MIN_WIDTH)
    ) U_ST_MIN_TICK_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_min_tick),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .time_counter(w_real_min),
        .o_tick(w_hour_tick)
    );

    //sec
    st_tick_counter #(
        .TIMES(60),
        .BIT_WIDTH(SEC_WIDTH)
    ) U_ST_SEC_TICK_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_sec_tick),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .time_counter(w_real_sec),
        .o_tick(w_min_tick)
    );

    //msec
    st_tick_counter #(
        .TIMES(100),
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_ST_MSEC_TICK_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick_100hz),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .time_counter(w_real_msec),
        .o_tick(w_sec_tick)
    );
    st_tick_gen_100hz U_ST_TICK_GEN_100HZ (
        .clk(clk),
        .rst(rst),
        .i_runstop(i_runstop),
        .i_clear(i_clear),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

module st_tick_counter #(
    parameter TIMES = 100,
    BIT_WIDTH = 7
) (
    input                          clk,
    input                          rst,
    input                          i_tick,
    input                          i_clear,
    input                          i_mode,
    output     [BIT_WIDTH - 1 : 0] time_counter,
    output reg                     o_tick
);
    // counter register 
    reg [BIT_WIDTH - 1:0] counter_reg, counter_next;

    assign time_counter = counter_reg;


    always @(posedge clk, posedge rst) begin  //결국 여기서 counter_reg에 counter_next를 넣어서 출력함
        if (rst) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;      //counter_reg:output counter_next:input
        end
    end
    //next counter CL : blocking(=)        
    always @(*) begin                //여기서 counter_reg는 입력이므로 딱히 바뀌는 값이 아님. next를 하는 게 맞다.
        counter_next = counter_reg;  //초기화
        o_tick = 1'b0;
        if (i_tick) begin
            //counter_reg:input, counter_next:output
            if (i_mode) begin
                //down
                counter_next = counter_reg - 1;
                if (counter_reg == 0) begin 
                    o_tick = 1'b1;
                    counter_next = TIMES - 1;
                end else begin
                    o_tick = 1'b0;
                end
            end else begin
                //up
                counter_next = counter_reg + 1;
                if (counter_reg == TIMES - 1) begin
                    o_tick = 1'b1;
                    counter_next = 0;
                end else begin
                    o_tick = 1'b0;
                end
            end
        end else if (i_clear) begin
            counter_next = 0;
            o_tick = 1'b0;
        end
    end

endmodule


//tick gen 100hz (1/100 sec)
module st_tick_gen_100hz (
    input clk,
    input rst,
    input i_runstop,
    input i_clear,
    output reg o_tick_100hz
);
    //100 Hz counter number * 1000 for simulation
    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT) -1:0] counter_reg;

    always @(posedge clk, posedge rst) begin

        if (rst) begin  //reset
            counter_reg  <= 0;
            o_tick_100hz <= 1'b0;
        end else begin
            if (i_runstop) begin
                counter_reg  <= counter_reg + 1;
                o_tick_100hz <= 1'b0;
                if (counter_reg == F_COUNT - 1) begin
                    counter_reg  <= 0;
                    o_tick_100hz <= 1'b1;
                end else begin   
                    o_tick_100hz <= 1'b0;
                end
            end else if (i_clear) begin
                counter_reg  <= 0;
                o_tick_100hz <= 1'b0;
            end
        end
    end


endmodule


module save_time #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input clk,
    input rst,
    input i_save,
    input i_view_mode,
    input i_clear,

    input [MSEC_WIDTH - 1:0] i_real_msec,
    input [ SEC_WIDTH - 1:0] i_real_sec,
    input [ MIN_WIDTH - 1:0] i_real_min,
    input [HOUR_WIDTH - 1:0] i_real_hour,

    output [MSEC_WIDTH - 1:0] o_msec,
    output [ SEC_WIDTH - 1:0] o_sec,
    output [ MIN_WIDTH - 1:0] o_min,
    output [HOUR_WIDTH - 1:0] o_hour


);
    //real time
    // 실시간 값을 담아둘 내부 Wire 

    // 캡처된 시간을 저장
    reg [MSEC_WIDTH - 1:0] r_saved_msec;
    reg [ SEC_WIDTH - 1:0] r_saved_sec;
    reg [ MIN_WIDTH - 1:0] r_saved_min;
    reg [HOUR_WIDTH - 1:0] r_saved_hour;

    // Save 펄스가 들어올 때 실시간 시간을 레지스터에 저장
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_saved_msec <= 0;
            r_saved_sec  <= 0;
            r_saved_min  <= 0;
            r_saved_hour <= 0;
        end else if(i_clear) begin
            r_saved_msec <= 0;
            r_saved_sec  <= 0;
            r_saved_min  <= 0;
            r_saved_hour <= 0;
        end else if (i_save) begin
            // 실시간 Wire의 값을 레지스터로 복사
            r_saved_msec <= i_real_msec;
            r_saved_sec  <= i_real_sec;
            r_saved_min  <= i_real_min;
            r_saved_hour <= i_real_hour;
        end
    end

    // MUX (멀티플렉서) 로직: 화면 모드에 따라 최종 출력 결정
    // i_view_mode가 1이면 저장된 값, 0이면 실시간 값 출력
    assign o_msec = (i_view_mode) ? r_saved_msec : i_real_msec;
    assign o_sec  = (i_view_mode) ? r_saved_sec : i_real_sec;
    assign o_min  = (i_view_mode) ? r_saved_min : i_real_min;
    assign o_hour = (i_view_mode) ? r_saved_hour : i_real_hour;

endmodule