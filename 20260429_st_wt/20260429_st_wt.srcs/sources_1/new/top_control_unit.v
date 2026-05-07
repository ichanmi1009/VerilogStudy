`timescale 1ns / 1ps

module top_control_unit (
    input clk,
    input rst,
    input btnR,
    input btnL,
    input btnU,
    input btnD,
    input [2:1] sw,

    output o_mode,
    output reg o_clear,
    output reg o_runstop,
    output reg o_set_mode,
    output reg [1:0] o_timesel,
    output reg o_digitsel,
    output reg [1:0] o_edit,

    output [7:1] led
    //led0 : st or wt display // led1 : msec,sec or min hour display // led2 : watch run mode display // led3 : watch setup mode
    //led4 : min1 cursor(LD10) //led5 : min10 cursor(LD11) //led6 : sec1,hour cursor(LD12) //led7 : sec10 cursor(LD13)
);

    // 상태 정의 (Localparam 사용)
    localparam INIT = 4'b0000;
    localparam SW_STOP = 4'b0001;
    localparam SW_RUN = 4'b0010;
    localparam SW_CLEAR = 4'b0011;
    localparam SW_MODE = 4'b0100;

    localparam W_RUN = 4'b0101;
    localparam W_SET_S1 = 4'b0110;
    localparam W_SET_S10 = 4'b0111;
    localparam W_SET_M1 = 4'b1000;
    localparam W_SET_M10 = 4'b1001;
    localparam W_SET_HOUR = 4'b1010;

    reg [3:0] current_state, next_state;
    reg mode_reg;  //ST mode register 저장용

    assign o_mode = mode_reg;

    // 현재 상태 및 모드 FF 업데이트
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= INIT;
            mode_reg <= 1'b0;
        end else begin
            current_state <= next_state;
            if (current_state == SW_MODE) mode_reg <= ~mode_reg;
        end
    end




    // 다음 상태 결정 로직 (Next State Logic)
    always @(*) begin
        next_state = current_state;

        case (current_state)
            INIT: begin
                if (sw[1] == 1'b1 && sw[2] == 1'b0) begin
                    next_state = W_RUN;
                end else if (sw[1] == 0) begin
                    next_state = SW_STOP;
                end
            end

            // 스톱워치 상태 전이
            SW_STOP: begin
                if (sw[1]) begin
                    next_state = W_RUN;
                end else if (btnR) begin
                    next_state = SW_RUN;
                end else if (btnL) begin
                    next_state = SW_CLEAR;
                end else if (btnD) begin
                    next_state = SW_MODE;
                end
            end
            SW_RUN: begin
                if (sw[1]) begin
                    next_state = W_RUN;
                end else if (btnR) begin
                    next_state = SW_STOP;
                end
            end

            SW_CLEAR, SW_MODE: next_state = SW_STOP;

            // 시계 상태 전이
            W_RUN: begin
                if (!sw[1]) begin
                    next_state = SW_STOP;
                end else if (sw[2]) begin
                    next_state = W_SET_S1;
                end
            end

            // 시계 설정 모드 순환 (btnL: 왼쪽 이동, btnR: 오른쪽 이동)
            W_SET_S1: begin
                if (!sw[2]) begin
                    next_state = W_RUN;
                end else if (btnL) begin
                    next_state = W_SET_S10;
                end else if (btnR) begin
                    next_state = W_SET_HOUR;
                end
            end
            W_SET_S10: begin
                if (!sw[2]) begin
                    next_state = W_RUN;
                end else if (btnL) begin
                    next_state = W_SET_M1;
                end else if (btnR) begin
                    next_state = W_SET_S1;
                end
            end
            W_SET_M1: begin
                if (!sw[2]) begin
                    next_state = W_RUN;
                end else if (btnL) begin
                    next_state = W_SET_M10;
                end else if (btnR) begin
                    next_state = W_SET_S10;
                end
            end
            W_SET_M10: begin
                if (!sw[2]) begin
                    next_state = W_RUN;
                end else if (btnL) begin
                    next_state = W_SET_HOUR;
                end else if (btnR) begin
                    next_state = W_SET_M1;
                end
            end
            W_SET_HOUR: begin
                if (!sw[2]) begin
                    next_state = W_RUN;
                end else if (btnL) begin
                    next_state = W_SET_S1;
                end else if (btnR) begin
                    next_state = W_SET_M10;
                end
            end

        endcase
    end

    // 출력 신호 결정 로직 (Output Logic)
    // 출력 신호 결정 로직 (상태별로 풀어서 나열)
    always @(*) begin
        // 1. 모든 출력의 기본값 설정 (Latch 방지를 위해 먼저 0으로 초기화)
        o_runstop  = 1'b0;
        o_clear    = 1'b0;
        o_set_mode = 1'b0;
        o_timesel  = 2'b00;
        o_digitsel = 1'b0;
        o_edit     = 2'b00;

        case (current_state)
            // --- 스톱워치 관련 상태 ---
            SW_STOP: begin
                o_runstop  = 1'b0;
                o_clear    = 1'b0;  //trouble
                o_set_mode = 1'b0;
            end

            SW_RUN: begin
                o_runstop = 1'b1;
            end

            SW_CLEAR: begin
                o_clear = 1'b1;
            end

            W_RUN: begin  //trouble 
                o_set_mode = 1'b0;
            end

            // --- 시계 설정 관련 상태 (각 자릿수별로 나열) ---
            W_SET_S1: begin
                o_set_mode = 1'b1;
                o_timesel  = 2'b10;  // 초(Second) 선택
                o_digitsel = 1'b1;  // 일의 자리 선택
                if (btnU) o_edit = 2'b01;  // 증가
                else if (btnD) o_edit = 2'b10;  // 감소
            end

            W_SET_S10: begin
                o_set_mode = 1'b1;
                o_timesel  = 2'b10;  // 초(Second) 선택
                o_digitsel = 1'b0;  // 십의 자리 선택
                if (btnU) o_edit = 2'b01;
                else if (btnD) o_edit = 2'b10;
            end

            W_SET_M1: begin
                o_set_mode = 1'b1;
                o_timesel  = 2'b01;  // 분(Minute) 선택
                o_digitsel = 1'b1;  // 일의 자리 선택
                if (btnU) o_edit = 2'b01;
                else if (btnD) o_edit = 2'b10;
            end

            W_SET_M10: begin
                o_set_mode = 1'b1;
                o_timesel  = 2'b01;  // 분(Minute) 선택
                o_digitsel = 1'b0;  // 십의 자리 선택
                if (btnU) o_edit = 2'b01;
                else if (btnD) o_edit = 2'b10;
            end

            W_SET_HOUR: begin
                o_set_mode = 1'b1;
                o_timesel  = 2'b00;  // 시(Hour) 선택
                o_digitsel = 1'b0;  // 전체 또는 십의 자리
                if (btnU) o_edit = 2'b01;
                else if (btnD) o_edit = 2'b10;
            end

            default: begin
                // INIT, W_RUN 등 나머지 상태는 기본값(0) 유지
            end
        endcase
    end

    //led 출력 제어로직
    assign led[1] = sw[1]; //sw[1] == 0 : stopwatch mode, sw[1] == 1 : watch mode
    assign led[2] = sw[1] & (!sw[2]); // sw[1] == 1 : watch mode, sw[2] == 0 : run mode
    assign led[3] = sw[1] & sw[2]; // sw[1] == 1 : watch mode, sw[2] == 1 : setup mode
    assign led[4] = (current_state == W_SET_M1)   ? 1'b1 : 1'b0; // 분(Minute) 일의 자리 설정 시 LED ON
    assign led[5] = (current_state == W_SET_M10)  ? 1'b1 : 1'b0; // 분(Minute) 십의 자리 설정 시 LED ON
    assign led[6] = (current_state == W_SET_S1 || current_state == W_SET_HOUR)   ? 1'b1 : 1'b0; // 초(Second) 일의 자리 또는 시(Hour) 설정 시 LED ON
    assign led[7] = (current_state == W_SET_S10) ? 1'b1 : 1'b0; // 초(Second) 십의 자리 설정 시 LED ON


endmodule
