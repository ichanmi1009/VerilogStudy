`timescale 1ns / 1ps

module tb_fifo ();

    parameter DEPTH = 4;

    reg clk;
    reg rst;
    reg push;
    reg pop;
    reg [7:0] push_data;
    wire [7:0] pop_data;
    wire full;
    wire empty;

    // random verification
    reg [7:0] compare_data[0:DEPTH-1]; // 비교할 대상 저장하는 곳, 크기는 DEPTH만큼 주소는 뺐다 넣었다 하면 되니까
    reg [1:0] push_cnt, pop_cnt;
    // 이거를 compare buffer에다 넣고 몇번 넣었는지 순서 기억하기 위한 용도/ push카운터가 몇개 차있는지 확인하는 용도 integer에서 배열로 수정해서 카운터가 3까지 밖에 안감

    fifo dut (
        .clk(clk),
        .rst(rst),
        .push_data(push_data),
        .push(push),
        .pop(pop),
        .pop_data(pop_data),
        .full(full),
        .empty(empty)
    );

    always #5 clk = ~clk;

    integer i;

    initial begin
        clk = 0;
        rst = 1;
        push_data = 0;
        push = 0;
        pop = 0;
        // reset
        #10 rst = 0;
        @(posedge clk);
        #1;
        // push only
        for (i = 0; i < DEPTH + 1; i = i + 1) begin
            push = 1;
            push_data = i;
            #10;
        end
        push = 0;  // push 동작 멈춤
        // pop only
        for (i = 0; i < DEPTH + 1; i = i + 1) begin
            pop = 1;
            #10;
        end

        // push pop
        push = 1;
        pop = 0;
        push_data = 8'h30;
        #10;
        for (i = 0; i < DEPTH + 1; i = i + 1) begin
            pop = 1;
            push_data = i + 8'h30;
            #10;
        end

        // empty fifo for random test
        pop  = 1;
        push = 0;
        #20;
        pop  = 0;
        push = 0;

        #20  // 비우고 시간딜레이 후 랜덤 테스트 하기 위해서

        // random test
        push_cnt = 0;
        pop_cnt = 0;

        // syncronize for drive signal
        @(posedge clk); // 앞에 이미 1n 줘서 그거 초기화하고 drive 동기맞추려고
        for (i = 0; i < 16; i = i + 1) begin
            // randomize pushdata, push, pop
            #1;
            push = $random % 2;  //push 0,1 두개
            pop = $random % 2;
            push_data = $random % 256;  // 8비트라서
            // compare data saving
            if (!full && push) begin
                compare_data[push_cnt] = push_data;
                push_cnt = push_cnt + 1;
            end
            @(negedge clk);
            if (!empty && pop) begin
                //compare
                if (pop_data == compare_data[pop_cnt]) begin
                    $display("%t : pass: pop_data = %h, compare data = %h",
                             $time, pop_data, compare_data[pop_cnt]);
                end else begin
                    $display("%t : fail: pop_data = %h, compare data = %h",
                             $time, pop_data, compare_data[pop_cnt]);
                end
                pop_cnt = pop_cnt + 1;
            end
            // full이면 full이 떠는지, empty면 empty 뜨는지 pass, fail 뜨는거 코드 짜보기
            // negedge 때문에 1n 틀어짐 
            //#6; //or @(posdege clk) #1, 입력지연만 햇을 때는 10n 줄수 없음 (#10)
            @(posedge clk);
        end

        #100;
        $stop;

    end

endmodule
