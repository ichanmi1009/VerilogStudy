`timescale 1ns / 1ps

module tb_comdot();
    `timescale 1ns / 1ps

    parameter SEC_DELAY = 1_000_000;
    parameter MIN_DELAY = 60_000_000; 


    reg clk, rst, i_shift, msec;
    wire o_cursor_in1, o_cursor_in2, o_cursor_in3, o_cursor_in4;


    cursor_ctrl dut(
        .clk(clk),
        .rst(rst),
        .i_shift_val(i_shift),
        .msec(msec),         
        .o_cursor_in1(o_cursor_in1),
        .o_cursor_in2(o_cursor_in2),
        .o_cursor_in3(o_cursor_in3),
        .o_cursor_in4(o_cursor_in4) 
    );


always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        i_shift = 0;


        msec = 4;

        @(negedge clk);
        @(negedge clk);
        @(negedge clk);

        rst = 0;
        i_shift = 4'b0001;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        i_shift = 4'b0010;

        msec = 60;
        // repeat(10) #(SEC_DELAY);
        // i_save = 0;
        // #(MIN_DELAY);
        // i_view_mode = 1;
        // #(MIN_DELAY);
        // i_view_mode = 0;

        // i_runstop = 0;
        // #(SEC_DELAY);
        // i_mode = 1;
        // #(SEC_DELAY);
        // i_runstop = 1;
        // #(MIN_DELAY);

        // i_save = 1;
        // repeat(10) #(SEC_DELAY);
        // i_save = 0;
        // #(MIN_DELAY);
        // i_view_mode = 1;
        // #(MIN_DELAY);
        // i_view_mode = 0;
        $stop;

    end





endmodule


