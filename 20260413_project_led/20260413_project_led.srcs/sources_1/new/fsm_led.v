`timescale 1ns / 1ps

module fsm_led (
    input clk,
    input rst,
    input [2:0] sw,
    output [2:0] led  // 일단 led reg 타입 지움
);
    parameter [2:0] STATE_A = 3'b000, STATE_B = 3'b001, STATE_C = 3'b010;
    parameter [2:0] STATE_D = 3'b100, STATE_E = 3'b111; // 스위치 입력 값이자 도착할 목적지 동시에 정의

    // state register
    reg [2:0] current_state, next_state;  // current_state, next_State 

    reg [2:0] led_reg, led_next;

    assign led = led_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            current_state <= STATE_A;
        end else begin
            current_state <= next_state;
            led_reg       <= led_next;
        end
    end

    // next state, ouput Combinational Logic + SL (현재 상태와 입력에 따라 next 상태가 바뀜), 입력이 바뀌면 바로 STATE 변화(조합논리라서)
    always @(*) begin  // 입력(state 감시)
        next_state = current_state;
        led_next   = led_reg;
        case (current_state)
            STATE_A: begin // reset에 의해 state가 a로 바뀌면 자동적으로 led 출력값도 초기화 되는 구조입니다.
                // led_next = 3'b000;  // moore output
                if (sw == STATE_B) begin
                    next_state = STATE_B;
                    led_next   = 3'b001;  // mealy output
                end else if (sw == STATE_C) begin
                    next_state = STATE_C;
                    led_next   = 3'b010;  // mealy output
                end else begin
                    next_state = current_state;
                end
            end
            STATE_B: begin
                // led_next = 3'b001;
                if (sw == STATE_C) begin
                    next_state = STATE_C;
                    led_next   = 3'b010;  // mealy output
                end else begin
                    next_state = current_state;
                end
            end
            STATE_C: begin
                // led_next = 3'b010;
                if (sw == STATE_D) begin
                    next_state = STATE_D;
                    led_next   = 3'b100;  // mealy output
                end else begin
                    next_state = current_state;
                end
            end
            STATE_D: begin
                // led_next = 3'b100;
                if (sw == STATE_B) begin
                    next_state = STATE_B;
                    led_next   = 3'b001;  // mealy output
                end else if (sw == STATE_A) begin
                    next_state = STATE_A;
                    led_next   = 3'b000;  // mealy output
                end else if (sw == STATE_E) begin
                    next_state = STATE_E;
                    led_next   = 3'b111;  // mealy output
                end else begin
                    next_state = current_state;
                end
            end
            STATE_E: begin
                // led_next = 3'b111;
                if (sw == STATE_A) begin
                    next_state = STATE_A;
                    led_next   = 3'b000;  // mealy output
                end else begin
                    next_state = current_state;
                end
            end
            //default: next_state = current_state;
        endcase
    end

    // output Combinational Logic

    /*
    always @(*) begin
        case (current_state)
            STATE_A: led = 3'b000;
            STATE_B: led = 3'b001;
            STATE_C: led = 3'b010;
            STATE_D: led = 3'b100;
            STATE_E: led = 3'b111;
            default: led = 3'b000;
        endcase
    end
*/

endmodule
