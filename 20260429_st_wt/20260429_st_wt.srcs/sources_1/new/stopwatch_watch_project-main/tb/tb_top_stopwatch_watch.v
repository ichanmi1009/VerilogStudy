`timescale 1ns / 1ps

module tb_top_stopwatch_watch;

    reg         clk;
    reg         rst;
    reg         btnR;
    reg         btnL;
    reg         btnU;
    reg         btnD;
    reg [2:0]   sw;

    wire [3:0]  fnd_com;
    wire [7:0]  fnd_data;
    wire [7:0]  led;

    top_stopwatch_watch dut (
        .clk      (clk),
        .rst      (rst),
        .btnR     (btnR),
        .btnL     (btnL),
        .btnU     (btnU),
        .btuD     (btnD),   // top module 포트명이 btuD
        .sw       (sw),
        .fnd_com  (fnd_com),
        .fnd_data (fnd_data),
        .led      (led)
    );

    // -------------------------------------------------
    // 내부 파라미터 가속
    // -------------------------------------------------
    defparam dut.UBTNR.F_COUNT = 4;
    defparam dut.UBTNL.F_COUNT = 4;
    defparam dut.UBTNU.F_COUNT = 4;
    defparam dut.UBTND.F_COUNT = 4;

    defparam dut.U_STOPWATCH_DATAPATH.U_TICK_GEN_100HZ.F_COUNT = 10;
    defparam dut.U_WATCH_DATAPATH.uTICK_GEN_100HZ.F_COUNT = 10;

    defparam dut.uFND_CNTL.DIV_COUNT = 2;

    // 10ns clock
    always #5 clk = ~clk;

    // -------------------------------------------------
    // task
    // -------------------------------------------------
    task apply_sw(input [2:0] sw_val);
    begin
        @(negedge clk);
        sw = sw_val;
    end
    endtask

    task press_btnR;
    begin
        @(negedge clk);
        btnR = 1'b1;
        repeat(40) @(negedge clk);   // debounce 통과용 충분한 유지
        btnR = 1'b0;
        repeat(20) @(negedge clk);
    end
    endtask

    task press_btnL;
    begin
        @(negedge clk);
        btnL = 1'b1;
        repeat(40) @(negedge clk);
        btnL = 1'b0;
        repeat(20) @(negedge clk);
    end
    endtask

    task press_btnU;
    begin
        @(negedge clk);
        btnU = 1'b1;
        repeat(40) @(negedge clk);
        btnU = 1'b0;
        repeat(20) @(negedge clk);
    end
    endtask

    task press_btnD;
    begin
        @(negedge clk);
        btnD = 1'b1;
        repeat(40) @(negedge clk);
        btnD = 1'b0;
        repeat(20) @(negedge clk);
    end
    endtask

    initial begin
        clk  = 1'b0;
        rst  = 1'b1;
        btnR = 1'b0;
        btnL = 1'b0;
        btnU = 1'b0;
        btnD = 1'b0;
        sw   = 3'b000;

        // ---------------------------------------------
        // 0) Reset
        // ---------------------------------------------
        #20;
        rst = 1'b0;

        // ---------------------------------------------
        // 1) Stopwatch mode (sw[1]=0)
        //    sw = {sw[2], sw[1], sw[0]}
        //    000 : stopwatch + msec/sec display
        // ---------------------------------------------
        apply_sw(3'b000);

        // Stopwatch run
        press_btnR();
        repeat(120) @(negedge clk);

        // Stopwatch stop
        press_btnR();
        repeat(60) @(negedge clk);

        // Stopwatch clear
        press_btnL();
        repeat(40) @(negedge clk);

        // Stopwatch direction change
        press_btnD();
        repeat(20) @(negedge clk);

        // Stopwatch run again (down count)
        press_btnR();
        repeat(120) @(negedge clk);

        // ---------------------------------------------
        // 2) Watch run mode
        //    010 : watch + run mode + msec/sec display
        // ---------------------------------------------
        apply_sw(3'b010);
        repeat(250) @(negedge clk);

        // ---------------------------------------------
        // 3) Watch setup mode
        //    110 : watch + setup mode + msec/sec display
        // ---------------------------------------------
        apply_sw(3'b110);
        repeat(40) @(negedge clk);   // 상태 전이 안정화

        // W_SET_S1 상태에서 sec 1의 자리 증가
        press_btnU();

        // W_SET_S10으로 이동 후 sec 10의 자리 증가
        press_btnL();
        press_btnU();

        // W_SET_M1으로 이동 후 min 1의 자리 감소
        press_btnL();
        press_btnD();

        // W_SET_M10으로 이동 후 min 10의 자리 증가
        press_btnL();
        press_btnU();

        // W_SET_HOUR로 이동 후 hour 증가
        press_btnL();
        press_btnU();

        // ---------------------------------------------
        // 4) Display select 변경
        //    111 : watch + setup mode + min/hour display
        // ---------------------------------------------
        apply_sw(3'b111);
        repeat(120) @(negedge clk);

        // ---------------------------------------------
        // 5) Watch run mode 복귀
        //    011 : watch + run mode + min/hour display
        // ---------------------------------------------
        apply_sw(3'b011);
        repeat(200) @(negedge clk);

        $finish;
    end

endmodule