`timescale 1ns / 1ps


module stopwatch_control_unit (
    input            clk,
    input            rst,
    input            i_mode,
    input            i_clear,
    input            i_run_stop,
    input            i_save,
    input      [3:0] sw,
    output           o_mode,
    output reg       o_clear,
    output reg       o_run_stop,


    output o_view_mode,
    output reg o_save

);


    //state
    parameter [1:0] STOP = 0, RUN = 1, CLEAR = 2, MODE = 3;
    reg [1:0] c_state, n_state;
    reg mode_reg, mode_next;




    assign o_view_mode = sw[3];

    reg btnu_d1, btnu_d2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btnu_d1 <= 1'b0;
            btnu_d2 <= 1'b0;
        end else begin
            btnu_d1 <= i_save;
            btnu_d2 <= btnu_d1;
        end
    end
    wire w_btnu_edge = btnu_d1 & ~btnu_d2;

    assign o_mode = mode_reg;  //현재 화면 모드를 전달


    assign o_led  = sw;

    //state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state  <= STOP;
            mode_reg <= 1'b0;  //up_count
        end else begin
            c_state  <= n_state;
            mode_reg <= mode_next;  //mode memory

        end
    end

    //next, output CL
    always @(*) begin
        n_state = c_state;
        mode_next = mode_reg;
        o_clear = 1'b0;
        o_run_stop = 1'b0;

        o_save = w_btnu_edge;


        case (c_state)
            STOP: begin
                o_run_stop = 1'b0;
                o_clear    = 1'b0;
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