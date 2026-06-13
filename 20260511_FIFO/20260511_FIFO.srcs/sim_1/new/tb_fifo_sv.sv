`timescale 1ns / 1ps
class transaction;  // transaction이므로 bit로 선언 logic 필요 없음

    rand bit       push;
    rand bit       pop;
    rand bit [7:0] push_data;
    bit      [7:0] pop_data;
    // bit            rst;
    bit            full;
    bit            empty;

    // int            test_mode;

    //constraint push_only {
    //    push =: 1/100, 0/0
    //}

    //constraint push_only {
    //    push dist {
    //        1 :/ 100,
    //        0 :/ 0
    //    };
    //    pop dist {
    //        1 :/ 0,
    //        0 :/ 100
    //    };
    //}

    function debug_print(string name);
        $display(
            "%t : [%s] push = %d, pop = %d, push_data = %d, pop_data = %d, full = %d, empty = %d",
            $time, name, push, pop, push_data, pop_data, full, empty);
    endfunction

endclass

interface fifo_interface;
    logic       clk;
    logic       rst;
    logic [7:0] push_data;
    logic       push;
    logic       pop;
    logic [7:0] pop_data;
    logic       full;
    logic       empty;
endinterface

class generator;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;  // 데이터 타입 transaction
    event event_gen_next;  //score board에서 오는 event

    function new(mailbox#(transaction) gen2drv_mbox, event event_gen_next);
        // 생성될 때 재정의 필요한 것
        this.gen2drv_mbox   = gen2drv_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run(int count);
        repeat (count) begin  // fork-join_any로 만드려고 repeat 씀
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            tr.debug_print("GEN");
            @(event_gen_next);
        end
    endtask
endclass

class driver;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event event_gen_next;  // 데이터 타입 transaction
    virtual fifo_interface fifo_vif;


    function new(mailbox#(transaction) gen2drv_mbox, event event_gen_next,
                 virtual fifo_interface fifo_vif);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.event_gen_next = event_gen_next;
        this.fifo_vif       = fifo_vif;
    endfunction

    task preset();
        fifo_vif.rst = 1;
        fifo_vif.push_data = 0;
        fifo_vif.push = 0;
        fifo_vif.pop = 0;

        repeat (2) @(posedge fifo_vif.clk);
        fifo_vif.rst = 0;
        // assertion은 내일 와서 수업

        @(negedge fifo_vif.clk);
        // assertion check full, empty
        assert (fifo_vif.empty) $display("[DRV Assert] reset pass : empty!");
        else $display("[DRV Assert] reset fail : empty = %d", fifo_vif.empty);

        assert (!fifo_vif.full) $display("[DRV Assert] reset pass : full!");
        else $display("[DRV Assert] reset fail : full = %d", fifo_vif.full);

    endtask

    // push only task 생성
    // randomize 생성해서 push data만 randomize

    // 뭐 타스크 여러개 써도되고. 에이전트 되고 클래스 되고
    task print(string name);

        $display(
            "%t : [%s] push = %d, pop = %d, push_data = %d, pop_data = %d, full = %d, empty = %d",
            $time, name, fifo_vif.push, fifo_vif.pop, fifo_vif.push_data,
            fifo_vif.pop_data, fifo_vif.full, fifo_vif.empty);
    endtask

    task push_only(int count);
        $display("fifo push only test");
        repeat (count) begin
            gen2drv_mbox.get(tr);
            @(posedge fifo_vif.clk);
            #1;
            fifo_vif.push = 1;
            fifo_vif.push_data = tr.push_data;
            fifo_vif.pop = 0;
            print("PUSH");
            ->event_gen_next;
        end
    endtask

    task pop_only(int count);
        $display("fifo pop only test");
        repeat (count) begin
            gen2drv_mbox.get(tr);
            @(posedge fifo_vif.clk);
            #1;
            fifo_vif.push = 0;
            fifo_vif.pop  = 1;
            print("POP");
            ->event_gen_next;
        end
    endtask



    task run();
        forever begin
            gen2drv_mbox.get(tr);
            tr.debug_print("DRV");
            @(posedge fifo_vif.clk);
            #1;
            fifo_vif.push = tr.push;
            fifo_vif.push_data = tr.push_data;
            fifo_vif.pop = tr.pop;
        end
    endtask


    // scoreboard는 통계 내기 좋고. 설계 모듈에도 넣을 수 잇음. push 신호가 발생하면 메모리에 저장. address가 바뀌면 rptr이 바뀌어야함 등
    // 특정 조건이 만족했을 때 passs, fail을 만들어본거
    // 시나리오를 만들어 놓고, 시나리오에 맞춰서 task fork~join으로 만들어보는게 중요


    // drv에서는 push_only 동작만하고
    // assertion은 monitor나 scoreboard
    // 어떻게 assertion을 띄우면 좋을지
    // scoreboard로 올려서 assertion scoreboard에 채우면 16개 되어ㅣㅅ을때 full 발상해서 assertion 채우고
    // push 16번 발생하면?
    // 조건 이벤트?


endclass

class monitor;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;  // 데이터 타입 transaction
    virtual fifo_interface fifo_vif;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual fifo_interface fifo_vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.fifo_vif     = fifo_vif;
    endfunction

    task run();
        forever begin
            @(negedge fifo_vif.clk);
            tr           = new();
            tr.push      = fifo_vif.push;
            tr.push_data = fifo_vif.push_data;
            tr.pop       = fifo_vif.pop;
            tr.pop_data  = fifo_vif.pop_data;
            tr.full      = fifo_vif.full;
            tr.empty     = fifo_vif.empty;
            mon2scb_mbox.put(tr);
            tr.debug_print("MON");
        end
    endtask


endclass

class scoreboard;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;  // 데이터 타입 transaction
    event event_gen_next;  //score board에서 오는 event

    bit [7:0] fifo_que[$:16];  // bit x,z 필요없음
    bit [7:0] compare_data;

    //pass,fail count
    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;

    function new(mailbox#(transaction) mon2scb_mbox, event event_gen_next);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run();
        forever begin  // event 추가?
            mon2scb_mbox.get(tr);
            tr.debug_print("SCB");
            total_cnt++;
            //pass fail
            if (tr.push && (!tr.full)) begin  // write senario
                fifo_que.push_front(tr.push_data);
            end
            if (tr.pop && (!tr.empty)) begin  // read senario
                // pass / fail decision
                compare_data = fifo_que.pop_back();
                if (tr.pop_data == compare_data) begin
                    pass_cnt++;
                    $display("%t : PASS !! pop_data = %d, compare_data = %d",
                             $time, tr.pop_data, compare_data);
                end else begin
                    fail_cnt++;
                    $display("%t : FAIL pop = %d, pop_data = %d, empty = %d",
                             $time, tr.pop, tr.pop_data, tr.empty);
                end
            end
            ->event_gen_next;
        end
    endtask
endclass


class environment;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event                  event_gen_next;

    virtual fifo_interface fifo_vif;

    int                    run_count;

    function new(virtual fifo_interface fifo_vif);
        gen2drv_mbox  = new;
        mon2scb_mbox  = new;
        gen           = new(gen2drv_mbox, event_gen_next);
        drv           = new(gen2drv_mbox, event_gen_next, fifo_vif);
        mon           = new(mon2scb_mbox, fifo_vif);
        scb           = new(mon2scb_mbox, event_gen_next);

        this.fifo_vif = fifo_vif;
    endfunction

    //fork join_any 적용

    task run();

        // ram interface initial
        // reset test by assertion
        drv.preset();

        // -> 랜더마이즈 하려고햇는데 push로 다 차있으니까 일단 막다운거임
        // push only test for full signal "1"
        run_count = 16;  //원래는 16
        fork
            gen.run(run_count);
            drv.push_only(run_count);
            //drv.pop_only(run_count);
            //drv.run();
            //mon.run();
            //scb.run();
        join
        $display("%t : [ENV] PUSH_ONLY TASK END", $time);
        #10;  // test가 끝나고 시간 지연을 조금 줘야 계산 가능
        // 조합출력 : 15, 순차출력 : 16 을 이야기 하셨음
        if (fifo_vif.full) $display("PASS : push only test");
        else $display("FAIL: push only test");

        fork
            gen.run(run_count);
            drv.pop_only(run_count);
        join
        $display("%t : [ENV] POP_ONLY TASK END", $time);
        #10;
        // 조합출력 : 15, 순차출력 : 16 이거 아니엇음
        if (fifo_vif.empty) $display("PASS : pop only test");
        else $display("FAIL: pop only test");

        fork
            gen.run(100);
            drv.run();
            mon.run();
            scb.run();
        join_any
        $display("fifo Constraint random test end");
        $display("%t : [ENV] ALL TASK END", $time);
        // 조합출력 : 15, 순차출력 : 16 이거 아니엇음

        #20;
        $display("__________________________");
        $display("** FIFO IP Verification **");
        $display("** total test num = %2d **", scb.total_cnt);
        $display("** pass test num  = %2d **", scb.pass_cnt);
        $display("** fail test num  = %2d **", scb.fail_cnt);
        $display("**************************");

        $stop;
    endtask

endclass



module tb_fifo_sv ();

    fifo_interface fifo_if ();  // 괄호 빼먹음 추가함
    environment env;

    fifo_sv dut (
        .clk      (fifo_if.clk),
        .rst      (fifo_if.rst),
        .push_data(fifo_if.push_data),
        .push     (fifo_if.push),
        .pop      (fifo_if.pop),
        .pop_data (fifo_if.pop_data),
        .full     (fifo_if.full),
        .empty    (fifo_if.empty)
    );

    always #5 fifo_if.clk = ~fifo_if.clk;

    initial begin
        fifo_if.clk = 0;
        env = new(fifo_if);
        env.run();
    end

endmodule


//push, pop 초기화
