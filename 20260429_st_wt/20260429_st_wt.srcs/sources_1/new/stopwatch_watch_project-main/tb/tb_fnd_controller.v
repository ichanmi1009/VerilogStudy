`timescale 1ns / 1ps

module tb_fnd_controller;

    // 시뮬레이션 시간을 줄이기 위해 DIV_COUNT를 작게 설정
    localparam DIV_COUNT_TB = 5;

    reg clk;
    reg rst;
    reg sw;

    reg [6:0] msec;
    reg [5:0] sec;
    reg [5:0] min;
    reg [4:0] hour;

    wire [3:0] fnd_com;
    wire [7:0] fnd_data;

    // waveform에서 구간 구분용
    reg [3:0] phase;

    // 내부 신호 모니터링용
    wire       w_1khz_mon;
    wire [2:0] digit_sel_mon;
    wire [3:0] out_mux_mon;
    wire [3:0] out_mux_msec_sec_mon;
    wire [3:0] out_mux_min_hour_mon;
    wire       dot_mon;

    assign w_1khz_mon           = dut.w_1khz;
    assign digit_sel_mon        = dut.w_digit_sel;
    assign out_mux_mon          = dut.w_out_mux;
    assign out_mux_msec_sec_mon = dut.w_out_mux_msec_sec;
    assign out_mux_min_hour_mon = dut.w_out_mux_min_hour;
    assign dot_mon              = dut.dot;

    fnd_controller #(
        .DIV_COUNT(DIV_COUNT_TB)
    ) dut (
        .clk      (clk),
        .rst      (rst),
        .sw       (sw),
        .msec     (msec),
        .sec      (sec),
        .min      (min),
        .hour     (hour),
        .fnd_com  (fnd_com),
        .fnd_data (fnd_data)
    );

    // 100MHz clock
    always #5 clk = ~clk;

    initial begin
        clk   = 1'b0;
        rst   = 1'b1;
        sw    = 1'b0;
        phase = 4'd0;

        // 테스트용 고정 시간값
        // sw=0일 때: msec/sec 표시 확인용
        // sw=1일 때: min/hour 표시 확인용
        msec = 7'd37;
        sec  = 6'd12;
        min  = 6'd45;
        hour = 5'd23;

        // reset
        #35;
        rst = 1'b0;

        // --------------------------------------------------
        // phase 1: sw=0, msec/sec 표시 구조 확인
        // msec=37, sec=12
        // digit_sel 기준 예상 선택값:
        // 0: msec 1의 자리 = 7
        // 1: msec 10의 자리 = 3
        // 2: sec 1의 자리  = 2
        // 3: sec 10의 자리 = 1
        // --------------------------------------------------
        phase = 4'd1;
        sw = 1'b0;
        wait_scan(10);

        // --------------------------------------------------
        // phase 2: sw=1, min/hour 표시 구조 확인
        // min=45, hour=23
        // digit_sel 기준 예상 선택값:
        // 0: min 1의 자리  = 5
        // 1: min 10의 자리 = 4
        // 2: hour 1의 자리 = 3
        // 3: hour 10의 자리 = 2
        // --------------------------------------------------
        phase = 4'd2;
        sw = 1'b1;
        wait_scan(10);

        // --------------------------------------------------
        // phase 3: dot indicator 확인 1
        // msec=25
        // --------------------------------------------------
        phase = 4'd3;
        sw = 1'b0;
        msec = 7'd25;
        wait_scan(8);

        // --------------------------------------------------
        // phase 4: dot indicator 확인 2
        // msec=75
        // --------------------------------------------------
        phase = 4'd4;
        msec = 7'd75;
        wait_scan(8);

        phase = 4'd5;
        wait_scan(3);

        $stop;
    end

    task wait_scan;
        input integer scan_count;
        integer i;
        begin
            for (i = 0; i < scan_count; i = i + 1) begin
                @(posedge dut.w_1khz);
                #1;
                $display(
                    "phase=%0d, time=%0t, sw=%b, digit_sel=%0d, out_mux=%h, fnd_com=%b, fnd_data=%h, dot=%b",
                    phase, $time, sw, dut.w_digit_sel, dut.w_out_mux, fnd_com, fnd_data, dut.dot
                );
            end
        end
    endtask

endmodule