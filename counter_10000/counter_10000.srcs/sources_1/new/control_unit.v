`timescale 1ns / 1ps

module control_unit (
    input clk,
    input rst,
    input i_mode,
    input i_clear,
    input i_run_stop,
    input i_btnu,  // re-define
    input [2:0] sw,
    output wire o_mode,  // assign문
    output reg o_clear,
    output reg o_run_stop,
    output      [2:0] o_led // led 래그 타입 바꿔서 컨트롤 유닛에 추가할수도 있고 스탑워치 fsm만 지금 추가, 워치에 대한 fsm그리고 설명 추가
);

    // state
    parameter [1:0] STOP = 0, RUN = 1, CLEAR = 2, MODE = 3;
    reg [1:0] c_state, n_state;
    reg mode_reg, mode_next;

    assign o_mode = mode_reg;  // o_mode 현재 모드 저장

    assign o_led  = sw;

    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state  <= STOP;
            mode_reg <= 1'b0;  // up_count
        end else begin
            c_state  <= n_state;
            mode_reg <= mode_next;  // mode memory
        end
    end

    // next, ouput CL
    always @(*) begin
        n_state = c_state;
        o_run_stop = 1'b0;  //reg니까 초기화
        o_clear = 1'b0;
        mode_next = mode_reg;
        case (c_state)
            STOP: begin
                o_run_stop = 1'b0;
                o_clear = 1'b0;

                if (i_run_stop) begin
                    n_state = RUN;
                end else if (i_clear) begin
                    n_state = CLEAR;
                end else if (i_mode) begin
                    n_state = MODE;
                end else n_state = c_state;
            end
            RUN: begin
                o_run_stop = 1'b1;
                if (i_run_stop) begin
                    n_state = STOP;
                end
            end
            CLEAR: begin
                o_clear = 1'b1;
                n_state = STOP;
            end
            MODE: begin
                //mode change
                mode_next = ~mode_reg;
                n_state   = STOP;
            end


        endcase

    end

endmodule
