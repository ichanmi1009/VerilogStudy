`timescale 1ns / 1ps

module watch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH  = 6,
    MIN_WIDTH  = 6,
    HOUR_WIDTH = 5
) (
    input                    clk,
    input                    rst,
    input                    i_up,
    input                    i_down,
    input                    i_left,
    input                    i_right,
    input               [3:0] sw,
    output [MSEC_WIDTH -1:0] msec,
    output [ SEC_WIDTH -1:0] sec,
    output [ MIN_WIDTH -1:0] min,
    output [HOUR_WIDTH -1:0] hour
  
);
    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;
    wire [3:0] w_o_num_shift;

    // hour
    wt_tick_counter #(
        .TIMES    (24),
        .BIT_WIDTH(HOUR_WIDTH),
        .INIT_VAL (12)
    ) U_WT_HOUR_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_hour_tick),
        .i_up        (sw[2] && w_o_num_shift[3] && i_up),
        .i_down      (sw[2] && w_o_num_shift[3] && i_down),
        .time_counter(hour),
        .o_tick      ()
    );

    // min
    wt_tick_counter #(
        .TIMES    (60),
        .BIT_WIDTH(MIN_WIDTH),
        .INIT_VAL (0)
    ) U_WT_MIN_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_up        (sw[2] && w_o_num_shift[2] && i_up),
        .i_down      (sw[2] && w_o_num_shift[2] && i_down),
        .i_tick      (w_min_tick),
        .time_counter(min),
        .o_tick      (w_hour_tick)
    );

    // sec
    wt_tick_counter #(
        .TIMES    (60),
        .BIT_WIDTH(SEC_WIDTH),
        .INIT_VAL (0)
    ) U_WT_SEC_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_sec_tick),
        .i_up        (sw[2] && w_o_num_shift[1] && i_up),
        .i_down      (sw[2] && w_o_num_shift[1] && i_down),
        .time_counter(sec),
        .o_tick      (w_min_tick)
    );

    // msec
    wt_tick_counter #(
        .TIMES    (100),
        .BIT_WIDTH(MSEC_WIDTH),
        .INIT_VAL (0)
    ) U_WT_MSEC_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_tick_100hz),
        .i_up        (sw[2] && w_o_num_shift[0] && i_up),
        .i_down      (sw[2] && w_o_num_shift[0] && i_down),
        .time_counter(msec),
        .o_tick      (w_sec_tick)
    );

    wt_tick_gen_100hz U_WT_TICK_GEN_100HZ (
        .clk         (clk),
        .rst         (rst),
        .o_tick_100hz(w_tick_100hz)
    );

    num_shift U_NUM_SHIFT (
        .clk        (clk),
        .rst        (rst),
        .i_left     (i_left),
        .i_right    (i_right),
        .o_num_shift(w_o_num_shift)
    );

endmodule


// tick_counter
module wt_tick_counter #(
    parameter TIMES     = 100,
    BIT_WIDTH = 7,
    INIT_VAL  = 0
) (
    input                    clk,
    input                    rst,
    input                    i_tick,
    input                    i_up,
    input                    i_down,
    output [BIT_WIDTH-1 : 0] time_counter,
    output reg               o_tick
);

    reg [BIT_WIDTH-1:0] counter_reg, counter_next;
    assign time_counter = counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= INIT_VAL;
        end else begin
            counter_reg <= counter_next;
        end
    end

    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;

        if (i_up) begin
            if (counter_reg == TIMES - 1) begin
                counter_next = 0;
            end else begin
                counter_next = counter_reg + 1;
            end
        end else if (i_down) begin
            if (counter_reg == 0) begin
                counter_next = TIMES - 1;
            end else begin
                counter_next = counter_reg - 1;
            end
        end else if (i_tick) begin
            if (counter_reg == TIMES - 1) begin
                o_tick       = 1'b1;
                counter_next = 0;
        end else begin
                counter_next = counter_reg + 1;
            end
        end
    end

endmodule


module wt_tick_gen_100hz (
    input      clk,
    input      rst,
    output reg o_tick_100hz
);
    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg  <= 0;
            o_tick_100hz <= 1'b0;
        end else begin
            if (counter_reg == F_COUNT - 1) begin
                counter_reg  <= 0;
                o_tick_100hz <= 1'b1;
            end else begin
                counter_reg  <= counter_reg + 1;
                o_tick_100hz <= 1'b0;
            end
        end
    end

endmodule


module num_shift (
    input        clk,
    input        rst,
    input        i_left,
    input        i_right,
    output [3:0] o_num_shift
);

    reg [3:0] shift_reg;
    assign o_num_shift = shift_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            shift_reg <= 4'b0001;
        end else begin
            if (i_left) begin 
            shift_reg <= {shift_reg[2:0], shift_reg[3]};
            end else if (i_right) begin 
            shift_reg <= {shift_reg[0], shift_reg[3:1]};
            end
        end
    end

endmodule