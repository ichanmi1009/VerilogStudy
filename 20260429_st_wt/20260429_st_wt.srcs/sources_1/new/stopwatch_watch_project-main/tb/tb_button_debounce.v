`timescale 1ns / 1ps

module tb_button_debounce;

    reg clk;
    reg rst;
    reg i_btn;
    wire o_btn;

    integer pulse_cnt;

    // 시뮬레이션용으로 sampling divider 축소
    button_debounce #(
        .F_COUNT(4)
    ) dut (
        .clk   (clk),
        .rst   (rst),
        .i_btn (i_btn),
        .o_btn (o_btn)
    );

    // 10ns clock
    always #5 clk = ~clk;

    // o_btn 펄스 개수 카운트
    always @(posedge clk or posedge rst) begin
        if (rst)
            pulse_cnt <= 0;
        else if (o_btn)
            pulse_cnt <= pulse_cnt + 1;
    end

    // 채터링이 섞인 버튼 입력
    task bounce_press;
    begin
        @(negedge clk); i_btn = 1'b1;
        @(negedge clk); i_btn = 1'b0;
        @(negedge clk); i_btn = 1'b1;
        @(negedge clk); i_btn = 1'b0;
        @(negedge clk); i_btn = 1'b1;
    end
    endtask

    // 버튼 길게 누르기
    task hold_press(input integer hold_cycles);
        integer k;
    begin
        @(negedge clk);
        i_btn = 1'b1;
        for (k = 0; k < hold_cycles; k = k + 1)
            @(negedge clk);
    end
    endtask

    // 버튼 떼기
    task release_btn(input integer idle_cycles);
        integer k;
    begin
        @(negedge clk);
        i_btn = 1'b0;
        for (k = 0; k < idle_cycles; k = k + 1)
            @(negedge clk);
    end
    endtask

    initial begin
        clk       = 1'b0;
        rst       = 1'b1;
        i_btn     = 1'b0;
        pulse_cnt = 0;

        // reset
        #20;
        rst = 1'b0;

        // -------------------------------------------------
        // CASE 1) 채터링 포함 1회 입력 -> o_btn 1회 기대
        // -------------------------------------------------
        $display("CASE 1: bouncing press start");
        bounce_press();
        // debounce 통과할 만큼 충분히 유지
        repeat(40) @(negedge clk);
        i_btn = 1'b0;
        repeat(20) @(negedge clk);

        $display("After CASE 1, pulse_cnt = %0d", pulse_cnt);

        // -------------------------------------------------
        // CASE 2) 길게 누르기 -> o_btn 추가 1회만 기대
        // -------------------------------------------------
        $display("CASE 2: long press start");
        hold_press(50);
        release_btn(20);

        $display("After CASE 2, pulse_cnt = %0d", pulse_cnt);

        // -------------------------------------------------
        // CASE 3) 다시 한 번 입력 -> o_btn 추가 1회 기대
        // -------------------------------------------------
        $display("CASE 3: second bouncing press start");
        bounce_press();
        repeat(40) @(negedge clk);
        i_btn = 1'b0;
        repeat(20) @(negedge clk);

        $display("After CASE 3, pulse_cnt = %0d", pulse_cnt);

        // 최종 결과 확인
        if (pulse_cnt == 3)
            $display("PASS: debounce output pulse count = %0d", pulse_cnt);
        else
            $display("FAIL: expected 3 pulses, got %0d", pulse_cnt);

        $finish;
    end

endmodule