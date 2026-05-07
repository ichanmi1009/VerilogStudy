`timescale 1ns / 1ps

module sr04 (

    input        clk,
    input        rst,
    input  [3:0] ultra_btn,
    input        echo,
    output [8:0] distance
);

    wire tick_us;

    sr04_controller u_sr04 (
        .clk(clk),
        .rst(rst),
        .sr04_start(ultra_btn[0]),
        .tick_us(w_tick_us),
        .echo(echo),
        .distance(distance)
    );

    tick_gen_us u_tick_gen (
        .clk(clk),
        .rst(rst),
        .tick_us(w_tick_us)
    );



endmodule


module sr04_controller (
    input        clk,
    input        rst,
    input        sr04_start,
    input        tick_us,
    input        echo,
    output [8:0] distance
);

    parameter IDLE = 0, START = 1, WAIT_ST = 2, RESPONSE = 3;

    reg [1:0] c_state, n_state;
    reg [15:0] count_reg, count_next;
    reg [8:0] dist_reg, dist_next;
    reg [5:0] us_tick_cnt, us_tick_cnt_next;

    assign distance = dist_reg;

    //SL current state, current out update
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state     <= IDLE;
            count_reg   <= 0;
            dist_reg    <= 0;
            us_tick_cnt <= 0;
        end else begin
            c_state     <= n_state;
            count_reg   <= count_next;
            dist_reg    <= dist_next;
            us_tick_cnt <= us_tick_cnt_next;
        end
    end

    //CL next state, next out update
    always @(*) begin
        n_state          = c_state;
        count_next       = count_reg;
        us_tick_cnt_next = us_tick_cnt;
        dist_next        = dist_reg;

        case (c_state)
            IDLE: begin
                count_next = 0;
                us_tick_cnt_next = 0;
                if (sr04_start) begin
                    dist_next = 0;
                    n_state   = START;

                end
            end

            START: begin

                if (tick_us) begin
                    if (count_reg > 11) begin
                        count_next = 0;
                        n_state = WAIT_ST;
                    end else begin
                        count_next = count_reg + 1;
                    end
                end
            end

            WAIT_ST: begin
                if (tick_us) begin
                    if (echo) begin
                        count_next = 0;
                        us_tick_cnt_next = 0;
                        n_state = RESPONSE;
                        dist_next = 0;
                    end
                end
            end
            RESPONSE: begin
                if (tick_us) begin
                    if (us_tick_cnt == 57) begin  // 58번째 us 틱일 때
                        us_tick_cnt_next = 0;
                        dist_next = dist_reg + 1;  // 1cm 증가
                    end else begin
                        us_tick_cnt_next = us_tick_cnt + 1;
                    end
                end
                if (!echo) begin
                    n_state = IDLE;
                    //dist_next = 0;
                end
            end
        endcase
    end

endmodule


module tick_gen_us (
    input      clk,
    input      rst,
    output reg tick_us
);

    parameter F_COUNT = 100_000_000 / 1_000_000;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_us <= 0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_us <= 1;
            end else begin
                tick_us <= 0;
            end
        end
    end

endmodule
