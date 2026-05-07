`timescale 1ns / 1ps

module tb_top_stopwatch_watch_18;

    reg clk;
    reg rst;

    reg btnR;
    reg btnL;
    reg btnU;
    reg btuD;

    reg [2:0] sw;

    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire [7:0] led;

    // 파형에서 구간 구분용
    reg [3:0] phase;

    top_stopwatch_watch dut (
        .clk      (clk),
        .rst      (rst),
        .btnR     (btnR),
        .btnL     (btnL),
        .btnU     (btnU),
        .btuD     (btuD),
        .sw       (sw),
        .fnd_com  (fnd_com),
        .fnd_data (fnd_data),
        .led      (led)
    );

    // 시뮬레이션 시간 단축용 파라미터 오버라이딩
    // Button Debounce 샘플링 시간을 줄임
    defparam dut.UBTNR.F_COUNT = 4;
    defparam dut.UBTNL.F_COUNT = 4;
    defparam dut.UBTNU.F_COUNT = 4;
    defparam dut.UBTND.F_COUNT = 4;

    // Stopwatch / Watch tick 생성 주기 단축
    defparam dut.U_STOPWATCH_DATAPATH.U_TICK_GEN_100HZ.F_COUNT = 4;
    defparam dut.U_WATCH_DATAPATH.uTICK_GEN_100HZ.F_COUNT = 4;

    // 100MHz clock
    always #5 clk = ~clk;

    // 내부 신호 모니터링용 alias
    wire [23:0] sw_data_mon   = dut.w_SW_data;
    wire [23:0] wt_data_mon   = dut.w_WT_data;
    wire [23:0] mux_out_mon   = dut.w_mux_out;

    wire [6:0]  msec_mon      = dut.w_msec;
    wire [5:0]  sec_mon       = dut.w_sec;
    wire [5:0]  min_mon       = dut.w_min;
    wire [4:0]  hour_mon      = dut.w_hour;

    wire [6:0]  msec_sw_mon   = dut.w_msec_sw;
    wire [5:0]  sec_sw_mon    = dut.w_sec_sw;
    wire [5:0]  min_sw_mon    = dut.w_min_sw;
    wire [4:0]  hour_sw_mon   = dut.w_hour_sw;

    wire [6:0]  msec_wt_mon   = dut.w_msec_wt;
    wire [5:0]  sec_wt_mon    = dut.w_sec_wt;
    wire [5:0]  min_wt_mon    = dut.w_min_wt;
    wire [4:0]  hour_wt_mon   = dut.w_hour_wt;

    wire        w_btnR_mon    = dut.w_btnR;
    wire        w_btnL_mon    = dut.w_btnL;
    wire        w_btnU_mon    = dut.w_btnU;
    wire        w_btnD_mon    = dut.w_btnD;

    wire        runstop_mon   = dut.w_runstop;
    wire        clear_mon     = dut.w_clear;
    wire        mode_mon      = dut.w_mode;

    wire        set_mode_mon  = dut.w_set_mode;
    wire [1:0]  time_sel_mon  = dut.w_time_sel;
    wire        digit_sel_mon = dut.w_digit_sel;
    wire [1:0]  edit_cmd_mon  = dut.w_edit_cmd;

    wire [3:0]  state_mon     = dut.uCONTROL_UNIT.current_state;

    initial begin
        clk   = 1'b0;
        rst   = 1'b1;

        btnR  = 1'b0;
        btnL  = 1'b0;
        btnU  = 1'b0;
        btuD  = 1'b0;

        sw    = 3'b000;
        phase = 4'd0;

        #100;
        rst = 1'b0;
        #100;

        // =====================================================
        // phase 1: Stopwatch/Watch 출력 선택 MUX 검증 - Stopwatch 선택
        // sw[1] = 0이면 Stopwatch 출력 선택
        // =====================================================
        phase = 4'd1;

        force dut.w_msec_sw = 7'd12;
        force dut.w_sec_sw  = 6'd34;
        force dut.w_min_sw  = 6'd56;
        force dut.w_hour_sw = 5'd7;

        force dut.w_msec_wt = 7'd98;
        force dut.w_sec_wt  = 6'd54;
        force dut.w_min_wt  = 6'd32;
        force dut.w_hour_wt = 5'd21;

        sw = 3'b000;   // sw[1]=0, Stopwatch 선택
        #200;

        // =====================================================
        // phase 2: Stopwatch/Watch 출력 선택 MUX 검증 - Watch 선택
        // sw[1] = 1이면 Watch 출력 선택
        // =====================================================
        phase = 4'd2;
        sw = 3'b010;   // sw[1]=1, Watch 선택
        #200;

        // =====================================================
        // phase 3: FND 입력 데이터 분리 검증
        // w_mux_out[6:0]   -> w_msec
        // w_mux_out[12:7]  -> w_sec
        // w_mux_out[18:13] -> w_min
        // w_mux_out[23:19] -> w_hour
        // =====================================================
        phase = 4'd3;
        sw = 3'b000;   // 다시 Stopwatch 선택
        #200;

        sw = 3'b010;   // Watch 선택
        #200;

        release dut.w_msec_sw;
        release dut.w_sec_sw;
        release dut.w_min_sw;
        release dut.w_hour_sw;

        release dut.w_msec_wt;
        release dut.w_sec_wt;
        release dut.w_min_wt;
        release dut.w_hour_wt;

        // =====================================================
        // phase 4: Top 모듈 통합 동작 검증 - Stopwatch Run
        // 버튼 입력 -> Debounce -> Control Unit -> Stopwatch Datapath
        // =====================================================
        phase = 4'd4;

        rst = 1'b1;
        #100;
        rst = 1'b0;
        #200;

        sw = 3'b000;   // Stopwatch mode
        #200;

        press_btnR();  // Stopwatch Run 진입
        #3000;

        // =====================================================
        // phase 5: Top 모듈 통합 동작 검증 - Stopwatch Stop
        // =====================================================
        phase = 4'd5;

        press_btnR();  // Stopwatch Stop 진입
        #1500;

        // =====================================================
        // phase 6: Top 모듈 통합 동작 검증 - Watch Run / Set mode 전환
        // sw[1]=1 : Watch 선택
        // sw[2]=0 : Watch Run mode
        // sw[2]=1 : Watch Set mode
        // =====================================================
        phase = 4'd6;

        sw = 3'b010;   // Watch Run mode
        #1000;

        sw = 3'b110;   // Watch Set mode
        #1000;

        press_btnL();  // 설정 위치 이동 확인
        #1000;

        press_btnU();  // 선택 자릿수 증가 edit 확인
        #1000;

        phase = 4'd7;
        #1000;

        $stop;
    end

    task press_btnR;
        begin
            btnR = 1'b1;
            #1000;
            btnR = 1'b0;
            #500;
        end
    endtask

    task press_btnL;
        begin
            btnL = 1'b1;
            #1000;
            btnL = 1'b0;
            #500;
        end
    endtask

    task press_btnU;
        begin
            btnU = 1'b1;
            #1000;
            btnU = 1'b0;
            #500;
        end
    endtask

    task press_btnD;
        begin
            btuD = 1'b1;
            #1000;
            btuD = 1'b0;
            #500;
        end
    endtask

endmodule