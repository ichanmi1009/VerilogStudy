`timescale 1ns / 1ps

module tb_watch_datapath;

    reg         clk;
    reg         rst;
    reg         i_set_mode;     // 0: run, 1: setup
    reg         i_digit_sel;    // 0: 10's digit, 1: 1's digit
    reg [1:0]   i_time_sel;     // 00: hour, 01: min, 10: sec
    reg [1:0]   i_edit_cmd;     // 00: none, 01: up, 10: down

    wire [3:0]  msec;
    wire [3:0]  sec_d1;
    wire [2:0]  sec_d10;
    wire [3:0]  min_d1;
    wire [2:0]  min_d10;
    wire [4:0]  hour;

    // MSEC_MOD를 줄여서 run mode carry를 빨리 확인
    watch_datapath #(
        .MSEC_MOD(10)
    ) dut (
        .clk        (clk),
        .rst        (rst),
        .i_set_mode (i_set_mode),
        .i_digit_sel(i_digit_sel),
        .i_time_sel (i_time_sel),
        .i_edit_cmd (i_edit_cmd),
        .msec       (msec),
        .sec_d1     (sec_d1),
        .sec_d10    (sec_d10),
        .min_d1     (min_d1),
        .min_d10    (min_d10),
        .hour       (hour)
    );

    // 내부 tick generator 가속
    defparam dut.uTICK_GEN_100HZ.F_COUNT = 10;

    always #5 clk = ~clk;

    task edit_up(input [1:0] time_sel, input digit_sel);
    begin
        @(negedge clk);
        i_set_mode  = 1'b1;
        i_time_sel  = time_sel;
        i_digit_sel = digit_sel;
        i_edit_cmd  = 2'b01;
        @(negedge clk);
        i_edit_cmd  = 2'b00;
    end
    endtask

    task edit_down(input [1:0] time_sel, input digit_sel);
    begin
        @(negedge clk);
        i_set_mode  = 1'b1;
        i_time_sel  = time_sel;
        i_digit_sel = digit_sel;
        i_edit_cmd  = 2'b10;
        @(negedge clk);
        i_edit_cmd  = 2'b00;
    end
    endtask

    initial begin
        clk         = 1'b0;
        rst         = 1'b1;
        i_set_mode  = 1'b0;
        i_digit_sel = 1'b0;
        i_time_sel  = 2'b00;
        i_edit_cmd  = 2'b00;

        // reset
        #20;
        rst = 1'b0;

        // -------------------------------------------------
        // 1) RUN MODE: msec/sec 증가 확인
        // -------------------------------------------------
        i_set_mode = 1'b0;
        repeat(120) @(negedge clk);
        repeat(120) @(negedge clk);
        repeat(120) @(negedge clk);
        repeat(120) @(negedge clk);
        repeat(120) @(negedge clk);
        repeat(120) @(negedge clk);
        repeat(120) @(negedge clk);
        repeat(120) @(negedge clk);
        repeat(120) @(negedge clk);
        repeat(120) @(negedge clk);
        repeat(120) @(negedge clk);
        repeat(120) @(negedge clk);
        repeat(120) @(negedge clk);

        // -------------------------------------------------
        // 2) SETUP MODE: sec 1의 자리 증가
        // -------------------------------------------------
        edit_up(2'b10, 1'b1);   // sec_d1++
        repeat(4) @(negedge clk);

        // sec 10의 자리 증가
        edit_up(2'b10, 1'b0);   // sec_d10++
        repeat(4) @(negedge clk);

        // min 1의 자리 증가
        edit_up(2'b01, 1'b1);   // min_d1++
        repeat(4) @(negedge clk);

        // min 10의 자리 감소
        edit_down(2'b01, 1'b0); // min_d10--
        repeat(4) @(negedge clk);

        // hour 증가
        edit_up(2'b00, 1'b0);   // hour++
        repeat(4) @(negedge clk);

        // -------------------------------------------------
        // 2) SETUP MODE: sec 1의 자리 증가
        // -------------------------------------------------
        edit_up(2'b10, 1'b1);   // sec_d1++
        repeat(4) @(negedge clk);

        // sec 10의 자리 증가
        edit_up(2'b10, 1'b0);   // sec_d10++
        repeat(4) @(negedge clk);

        // min 1의 자리 증가
        edit_up(2'b01, 1'b1);   // min_d1++
        repeat(4) @(negedge clk);

        // min 10의 자리 감소
        edit_down(2'b01, 1'b0); // min_d10--
        repeat(4) @(negedge clk);

        // hour 증가
        edit_up(2'b00, 1'b0);   // hour++
        repeat(4) @(negedge clk);


                // -------------------------------------------------
        // 2) SETUP MODE: sec 1의 자리 증가
        // -------------------------------------------------
        edit_up(2'b10, 1'b1);   // sec_d1++
        repeat(4) @(negedge clk);

        // sec 10의 자리 증가
        edit_up(2'b10, 1'b0);   // sec_d10++
        repeat(4) @(negedge clk);

        // min 1의 자리 증가
        edit_up(2'b01, 1'b1);   // min_d1++
        repeat(4) @(negedge clk);

        // min 10의 자리 감소
        edit_down(2'b01, 1'b0); // min_d10--
        repeat(4) @(negedge clk);

        // hour 증가
        edit_up(2'b00, 1'b0);   // hour++
        repeat(4) @(negedge clk);

                // -------------------------------------------------
        // 2) SETUP MODE: sec 1의 자리 증가
        // -------------------------------------------------
        edit_up(2'b10, 1'b1);   // sec_d1++
        repeat(4) @(negedge clk);

        // sec 10의 자리 증가
        edit_up(2'b10, 1'b0);   // sec_d10++
        repeat(4) @(negedge clk);

        // min 1의 자리 증가
        edit_up(2'b01, 1'b1);   // min_d1++
        repeat(4) @(negedge clk);

        // min 10의 자리 감소
        edit_down(2'b01, 1'b0); // min_d10--
        repeat(4) @(negedge clk);

        // hour 증가
        edit_up(2'b00, 1'b0);   // hour++
        repeat(4) @(negedge clk);


                // -------------------------------------------------
        // 2) SETUP MODE: sec 1의 자리 증가
        // -------------------------------------------------
        edit_up(2'b10, 1'b1);   // sec_d1++
        repeat(4) @(negedge clk);

        // sec 10의 자리 증가
        edit_up(2'b10, 1'b0);   // sec_d10++
        repeat(4) @(negedge clk);

        // min 1의 자리 증가
        edit_up(2'b01, 1'b1);   // min_d1++
        repeat(4) @(negedge clk);

        // min 10의 자리 감소
        edit_down(2'b01, 1'b0); // min_d10--
        repeat(4) @(negedge clk);

        // hour 증가
        edit_up(2'b00, 1'b0);   // hour++
        repeat(4) @(negedge clk);


        // -------------------------------------------------
        // 3) 다시 RUN MODE 복귀
        // -------------------------------------------------
        @(negedge clk);
        i_set_mode = 1'b0;
        i_edit_cmd = 2'b00;
        repeat(80) @(negedge clk);

        $finish;
    end

endmodule