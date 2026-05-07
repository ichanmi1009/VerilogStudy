`timescale 1ns / 1ps

module TOP_sr04_controller (
    input        clk,
    input        rst,
    input        btn_R,
    input        echo,
    output       trig,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);

    wire w_sr04_start;
    wire w_tick_us, w_tick_58us;
    wire [8:0] w_distance;

    ila_0 U_ILA_0 (
        .clk(clk),  //넣어주는 클럭은 무조건 시스템 클럭
        .probe0(w_sr04_start),
        .probe1(w_distance)
    );

    button_debounce U_BD_SR04_START (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_R),
        .o_btn(w_sr04_start)
    );

    sr04_controller U_SR04_CTNL (
        .clk(clk),
        .rst(rst),
        .sr04_start(sw04_start),
        .tick_us(w_tick_us),
        .tick_58us(w_tick_58us),
        .echo(echo),
        .trig(trig),
        .distance(distance)
    );

    tick_gen_us U_TICK_GEN_US (
        .clk(clk),
        .rst(rst),
        .tick_us(w_tick_us)
    );

    tick_gen_58us U_TICK_GEN_58US (
        .clk(clk),
        .rst(rst),
        .tick_58us(w_tick_58us)
    );

    fnd_controller U_FND_CNTL (
        .clk(clk),
        .rst(rst),
        .fnd_in({5'b00000, w_distance}),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );


endmodule





module sr04_controller (
    input        clk,
    input        rst,
    input        sr04_start,
    input        tick_us,
    input        tick_58us,
    input        echo,
    output       trig,
    output [8:0] distance
);
    parameter [1:0] IDLE = 0, START = 1, WAIT = 2, RESPONSE = 3;
    reg [1:0] c_state, n_state;
    reg [8:0] tick_cnt_reg, tick_cnt_next;
    reg trig_reg, trig_next;
    reg [8:0] distance_reg, distance_next;
    assign trig = trig_reg;
    assign distance = distance_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            tick_cnt_reg <= 0;
            trig_reg <= 0;
            distance_reg <= 0;
        end else begin
            c_state <= n_state;
            tick_cnt_reg <= tick_cnt_next;
            trig_reg <= trig_next;
            distance_reg <= distance_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        tick_cnt_next = tick_cnt_reg;
        trig_next = trig_reg;
        distance_next = distance_reg;
        case (c_state)
            IDLE: begin
                trig_next = 1'b0;
                tick_cnt_next = 0;
                if (sr04_start == 1) begin
                    n_state = START;
                end
            end
            START: begin
                trig_next = 1'b1;  // 트리거가 11us 정도 동작
                if (tick_us) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                end else if (tick_cnt_reg == 11) begin
                    n_state = WAIT;
                end
            end
            WAIT: begin
                trig_next = 1'b0;
                if (tick_us) begin // tick이 들어온거 보고 나중에 echo보기
                    if (echo == 1) begin
                        tick_cnt_next = 0;
                        n_state = RESPONSE; //echo가 1이면서 tick이 1이면 증가
                    end
                end
            end
            RESPONSE: begin
                if (tick_58us) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                end else if (echo == 0) begin
                    distance_next = tick_cnt_reg;
                    n_state = IDLE;
                end
            end
        endcase
    end


endmodule

module tick_gen_58us (
    input      clk,
    input      rst,
    output reg tick_58us
);

    parameter F_COUNT = 100_000_000 / (17241);  //1us
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_58us   <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_58us   <= 1'b1;
            end else begin
                tick_58us <= 1'b0;
            end
        end
    end

endmodule

module tick_gen_us (
    input      clk,
    input      rst,
    output reg tick_us
);

    parameter F_COUNT = 100_000_000 / 1_000_000;  //1us
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_us     <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_us     <= 1'b1;
            end else begin
                tick_us <= 1'b0;
            end
        end
    end

endmodule
