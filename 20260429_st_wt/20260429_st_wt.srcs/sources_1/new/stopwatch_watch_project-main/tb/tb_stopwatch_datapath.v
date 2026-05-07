`timescale 1ns / 1ps

module tb_stopwatch_datapath();

    reg         clk;
    reg         rst;
    reg         i_runstop;
    reg         i_clear;
    reg         i_mode;      // 0: up, 1: down

    wire [6:0]  msec;
    wire [5:0]  sec;
    wire [5:0]  min;
    wire [4:0]  hour;

    stopwatch_datapath dut (
        .clk        (clk),
        .rst        (rst),
        .i_runstop  (i_runstop),
        .i_clear    (i_clear),
        .i_mode     (i_mode),
        .msec       (msec),
        .sec        (sec),
        .min        (min),
        .hour       (hour)
    );

    // 내부 100Hz tick generator 가속
    defparam dut.U_TICK_GEN_100HZ.F_COUNT = 10;

    always #5 clk = ~clk;

    task pulse_clear;
    begin
        @(negedge clk);
        i_clear = 1'b1;
        @(negedge clk);
        i_clear = 1'b0;
    end
    endtask

    initial begin
        clk       = 1'b0;
        rst       = 1'b1;
        i_runstop = 1'b0;
        i_clear   = 1'b0;
        i_mode    = 1'b0;

        // reset
        #20;
        rst = 1'b0;

        // 1) up count run
        @(negedge clk);
        i_runstop = 1'b1;
        i_mode    = 1'b0;
        repeat(40) @(negedge clk);   // msec 증가 관찰

        // 2) stop
        @(negedge clk);
        i_runstop = 1'b0;
        repeat(15) @(negedge clk);   // 값 유지 확인

        // // 3) run again
        // @(negedge clk);
        // i_runstop = 1'b1;
        // repeat(20) @(negedge clk);

        // 4) clear
        pulse_clear();
        repeat(15) @(negedge clk);

        // 5) down count
        // 먼저 조금 올려놓고
        @(negedge clk);
        i_mode    = 1'b0;
        i_runstop = 1'b1;
        repeat(10) @(negedge clk);

        // down으로 변경
        @(negedge clk);
        i_runstop = 1'b0;
        i_mode    = 1'b1;
        @(negedge clk);
        i_runstop = 1'b1;
        repeat(50) @(negedge clk);

        // // stop
        // @(negedge clk);
        // i_runstop = 1'b0;
        // repeat(10) @(negedge clk);

        $finish;
    end

endmodule
