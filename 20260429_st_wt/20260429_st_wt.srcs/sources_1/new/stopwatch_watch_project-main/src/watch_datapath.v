`timescale 1ns / 1ps

module watch_datapath #(
    parameter MSEC_MOD  = 100   ,
    parameter MOD_6  = 6        ,
    parameter MOD_10 = 10       ,
    parameter HOUR_MOD  = 24    ,
    parameter MSEC_WIDTH    = $clog2(MSEC_MOD)  ,
    parameter SEC1_WIDTH    = $clog2(MOD_10)  ,
    parameter SEC10_WIDTH   = $clog2(MOD_6) ,
    parameter MIN1_WIDTH    = $clog2(MOD_10)  ,
    parameter MIN10_WIDTH   = $clog2(MOD_6) ,
    parameter HOUR_WIDTH    = $clog2(HOUR_MOD))(
    input                           clk         ,
    input                           rst         ,
    input                           i_set_mode  , //  0 : runmode : clockRUN,1 : setmode: clockSTOP
    input                           i_digit_sel, // 0: digit 10, 1: digit 1
    input  [1:0]                    i_time_sel  , // 00: hour, 01: min, 10 : sec
    input  [1:0]                    i_edit_cmd  , //01:up, 10:down, default:00
    output [MSEC_WIDTH - 1:0]       msec        ,
    output [SEC1_WIDTH - 1:0]       sec_d1      ,    
    output [SEC10_WIDTH - 1:0]      sec_d10     ,    
    output [MIN1_WIDTH - 1:0]       min_d1      ,
    output [MIN10_WIDTH - 1:0]      min_d10     ,
    output [HOUR_WIDTH - 1:0]       hour        
);

    wire    w_tick_100hz    ,
            w_msec_tick     , 
            w_sec1_tick     , 
            w_sec10_tick    , 
            w_min1_tick     , 
            w_min10_tick    ;
    
    reg [1:0] r_edit_sec1, r_edit_sec10, r_edit_min1, r_edit_min10, r_edit_hour;

    //edit_cmd
    always @(*) begin
        // default assignment to prevent unintended latch inference
        r_edit_sec1  = 2'b00;
        r_edit_sec10 = 2'b00;
        r_edit_min1  = 2'b00;
        r_edit_min10 = 2'b00;
        r_edit_hour  = 2'b00;   
                
        case(i_time_sel)
            2'b00 :  begin // 00: hour
                r_edit_hour =  i_edit_cmd;    
            end
            2'b01 :  begin // 01: min
                if(i_digit_sel) begin // 0: digit 10, 1: digit 1
                   r_edit_min1 =  i_edit_cmd;    
                end
                else begin
                    r_edit_min10 =  i_edit_cmd;
                end                
            end
            2'b10 :  begin // 10 : sec
                if(i_digit_sel) begin // 0: digit 10, 1: digit 1
                   r_edit_sec1 =  i_edit_cmd;    
                end
                else begin
                    r_edit_sec10 =  i_edit_cmd;
                end                
            end
        endcase
    end


    //Hour cnt mod24
    tick_counter_wt #(
        .TIMES(HOUR_MOD),
        .BIT_WIDTH($clog2(HOUR_MOD))
    )uHOUR_CNT(
        .clk(clk),
        .rst(rst),
        .i_tick(w_min10_tick),
        .i_edit_cmd(r_edit_hour),   // 00:none, 01:up, 10:down
        .time_counter(hour), //시
        .o_tick()
    );

    //Min_digit10 cnt mod6
    tick_counter_wt #(
        .TIMES(MOD_6),
        .BIT_WIDTH($clog2(MOD_6))
    )uMIN10_CNT(
        .clk(clk),
        .rst(rst),
        .i_tick(w_min1_tick),
        .i_edit_cmd(r_edit_min10),   // 00:none, 01:up, 10:down
        .time_counter(min_d10), //분 10의 자리
        .o_tick(w_min10_tick)
    );

    //Min_digit1_cnt mod10
    tick_counter_wt #(
        .TIMES(MOD_10),
        .BIT_WIDTH($clog2(MOD_10))
    )uMIN1_CNT(
        .clk(clk),
        .rst(rst),
        .i_tick(w_sec10_tick),
        .i_edit_cmd(r_edit_min1),   // 00:none, 01:up, 10:down
        .time_counter(min_d1), //분 1의 자리
        .o_tick(w_min1_tick)
    );

    //Sec_digit10_cnt mod6
    tick_counter_wt #(
        .TIMES(MOD_6),
        .BIT_WIDTH($clog2(MOD_6))
    )uSEC10_CNT(
        .clk(clk),
        .rst(rst),
        .i_tick(w_sec1_tick),
        .i_edit_cmd(r_edit_sec10),   // 00:none, 01:up, 10:down
        .time_counter(sec_d10),
        .o_tick(w_sec10_tick)
    );

    //Sec_digit1_cnt mod10
    tick_counter_wt #(
        .TIMES(MOD_10),
        .BIT_WIDTH($clog2(MOD_10))
    )uSEC1_CNT(
        .clk(clk),
        .rst(rst),
        .i_tick(w_msec_tick),
        .i_edit_cmd(r_edit_sec1),   // 00:none, 01:up, 10:down
        .time_counter(sec_d1),
        .o_tick(w_sec1_tick)
    );

    //MSEC_cnt mod100
    tick_counter_wt #(
        .TIMES(MSEC_MOD),
        .BIT_WIDTH($clog2(MSEC_MOD))
    )uMSEC_CNT(
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick_100hz),
        .i_edit_cmd(2'b00),   // 00:none, 01:up, 10:down
        .time_counter(msec),
        .o_tick(w_msec_tick)
    );

    // tick gen 100hz
    tick_gen_100hz_wt uTICK_GEN_100HZ(
        .clk         (clk         ),
        .rst         (rst         ),
        .i_run_en    (~i_set_mode ), 
        .o_tick_100hz(w_tick_100hz)
    );


endmodule



module tick_counter_wt #(
    parameter TIMES = 100,
    parameter BIT_WIDTH = 7
)(
    input                           clk,
    input                           rst,
    input                           i_tick,
    input       [1:0]               i_edit_cmd,   // 00:none, 01:up, 10:down
    output      [BIT_WIDTH-1:0]     time_counter,
    output                          o_tick
);

    reg [BIT_WIDTH-1:0] counter_reg, counter_next;

    assign time_counter = counter_reg;
    assign o_tick = i_tick && (counter_reg == TIMES - 1);

    always @(posedge clk or posedge rst) begin
        if (rst)
            counter_reg <= 0;
        else
            counter_reg <= counter_next;
    end

    always @(*) begin
        counter_next = counter_reg;

        if (i_tick) begin
            if (counter_reg == TIMES - 1)
                counter_next = 0;
            else
                counter_next = counter_reg + 1'b1;
        end
        else begin //setmode시 tick이 안 들어옴.
            case (i_edit_cmd)
                2'b01: begin
                    if (counter_reg == TIMES - 1)
                        counter_next = 0;
                    else
                        counter_next = counter_reg + 1'b1;
                end

                2'b10: begin
                    if (counter_reg == 0)
                        counter_next = TIMES - 1;
                    else
                        counter_next = counter_reg - 1'b1;
                end

                default: begin
                    counter_next = counter_reg;
                end
            endcase
        end
    end

endmodule


// tick gen 100hz
module tick_gen_100hz_wt (
    input           clk             ,
    input           rst             ,
    input           i_run_en        ,
    output reg      o_tick_100hz
);
    //100 Hz counter number
    //100 Hz * 10000 for simulation  / F_COUNT = 100_000_000 / 100;
    parameter F_COUNT = 100_000_000 / 100; // 100MHz/100Hz
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    
    always@(posedge clk, posedge rst) begin
        if(rst) begin
            counter_reg     <= 0;
            o_tick_100hz    <= 1'b0;
        end
        else if(i_run_en) begin
            counter_reg     <= counter_reg + 1'b1;
            o_tick_100hz    <= 1'b0;
            if(counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                o_tick_100hz      <= 1'b1;
            end 
            else begin
                o_tick_100hz      <= 1'b0;
            end                
        end 
        else begin
            counter_reg     <= counter_reg;
            o_tick_100hz    <= 1'b0;
        end
    end

endmodule

