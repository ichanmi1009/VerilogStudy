`timescale 1ns / 1ps

class transaction;  // transaction이므로 bit로 선언 logic 필요 없음


    rand bit [7:0] tx_data;
    bit [7:0] out_tx_data;
    // bit            tx_start; : data 보낼려면 tx_start가 1이어야 하니까 랜덤으로 보낼 필요 없음

    function debug_print(string name);
        $display("%t : [%s] random_tx_data = %d, out_tx_data = %d", $time,
                 name, tx_data, out_tx_data);
    endfunction

endclass

interface uart_interface;


    logic       clk;
    logic       rst;
    logic       tx_start;
    logic [7:0] tx_data;
    // logic       b_tick;
    logic       tx;
    logic       tx_busy;

endinterface

class generator;

    transaction tr1, tr2;
    mailbox #(transaction) gen2drv_mbox;  // 데이터 타입 transaction
    mailbox #(transaction) gen2scb_mbox;
    event event_gen_next;  //monitor에서 오는 event

    function new(mailbox#(transaction) gen2drv_mbox,
                 mailbox#(transaction) gen2scb_mbox, event event_gen_next);
        // 생성될 때 재정의 필요한 것
        this.gen2drv_mbox   = gen2drv_mbox;
        this.gen2scb_mbox   = gen2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run(int count);
        repeat (count) begin  // fork-join_any로 만드려고 repeat 씀
            tr1 = new();
            tr1.randomize();

            tr2 = new();
            tr2.tx_data = tr1.tx_data;

            gen2scb_mbox.put(tr2);  // 스코어보드용 tr
            gen2drv_mbox.put(tr1);  // 드라이브용 tr

            tr1.debug_print("GEN");
            tr2.debug_print("GEN");
            @(event_gen_next);
        end
    endtask
endclass

class driver;


    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual uart_interface uart_vif;


    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual uart_interface uart_vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.uart_vif     = uart_vif;
    endfunction

    task drive_byte(transaction tr);

        bit [9:0] uart_frame;

        // 전송 전 IDLE 고정(HIGH)
        uart_vif.tx = 1;
        #104160

            //{stop_bit(1), tr.load_data, start_bit(0)}
            uart_frame = {
                1'b1, tr.tx_data, 1'b0
            };

        for (int i = 0; i < 10; i++) begin
            uart_vif.tx = uart_frame[i];
            #104160;  // 9600bps 속도에 맞춰 한 비트 유지 시간
        end

        // 전송 후 IDLE 상태 유지
        uart_vif.tx = 1;
        #104160;

    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            tr.debug_print("DRV");
            drive_byte(tr);
        end
    endtask


    task preset();
        uart_vif.rst = 1;
        uart_vif.tx  = 1;

        repeat (2) @(posedge uart_vif.clk);
        uart_vif.rst = 0;

    endtask


endclass

class monitor;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;  // 데이터 타입 transaction
    virtual uart_interface uart_vif;
    event event_gen_next;

    function new(mailbox#(transaction) mon2scb_mbox, event event_gen_next,
                 virtual uart_interface uart_vif);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.event_gen_next = event_gen_next;
        this.uart_vif       = uart_vif;
    endfunction

    // 정밀한 타이밍으로 신호를 관찰
    task monitor_tx();

        bit [7:0] collected_data;

        wait (uart_vif.tx == 0);

        // WAIT
        #(104160 / 2);

        // DATA
        for (int i = 0; i < 8; i++) begin
            #104160;
            collected_data[i] = uart_vif.tx;
            $display("[MON] Sampling bit at center : value = %d", uart_vif.tx);
        end

        #104160;
        if (uart_vif.tx == 1) begin
            tr = new();
            tr.out_tx_data = collected_data;

            mon2scb_mbox.put(tr);
            tr.debug_print("MON");
        end else begin
            $display("uart frame fail (STOP bit error)");
        end

    endtask

    task run();
        forever begin
            monitor_tx();

            ->event_gen_next;
        end
    endtask

endclass

class scoreboard;

    mailbox #(transaction) gen2scb_mbox;
    mailbox #(transaction) mon2scb_mbox;  // 데이터 타입 transaction

    bit [7:0] compare_data;

    //pass,fail count
    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;

    function new(mailbox#(transaction) mon2scb_mbox,
                 mailbox#(transaction) gen2scb_mbox);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
    endfunction

    task run();
        transaction tr_gen, tr_mon;
        forever begin  // event 추가?
            gen2scb_mbox.get(tr_gen);
            mon2scb_mbox.get(tr_mon);
            tr_gen.debug_print("SCB");
            tr_mon.debug_print("SCB");

            total_cnt++;
            //pass fail
            if (tr_gen.tx_data == tr_mon.out_tx_data) begin
                pass_cnt++;
                $display("%t : PASS !! expected_data = %d, got tx_data = %d",
                         $time, tr_gen.tx_data, tr_mon.out_tx_data);
            end else begin
                fail_cnt++;
                $display("%t : FAIL expected_data = %d, got tx_data = %d",
                         $time, tr_gen.tx_data, tr_mon.out_tx_data);
            end
        end
    endtask
endclass


class environment;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) gen2scb_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event                  event_gen_next;

    virtual uart_interface uart_vif;

    int                    run_count;

    function new(virtual uart_interface uart_vif);
        gen2drv_mbox  = new;
        gen2scb_mbox  = new;
        mon2scb_mbox  = new;
        gen           = new(gen2drv_mbox, gen2scb_mbox, event_gen_next);
        drv           = new(gen2drv_mbox, uart_vif);
        mon           = new(mon2scb_mbox, event_gen_next, uart_vif);
        scb           = new(mon2scb_mbox, gen2scb_mbox);

        this.uart_vif = uart_vif;
    endfunction

    //fork join_any 적용

    task run();

        // ram interface initial
        // reset test by assertion
        drv.preset();

        // -> 랜더마이즈 하려고햇는데 push로 다 차있으니까 일단 막다운거임
        // push only test for full signal "1"
        // run_count = 16;  //원래는 16

        fork
            gen.run(100);
            drv.run();
            mon.run();
            scb.run();
        join_any
        $display("uart tx Constraint random test end");
        $display("%t : [ENV] ALL TASK END", $time);
        // 조합출력 : 15, 순차출력 : 16 이거 아니엇음

        #20;
        $display("__________________________");
        $display("** URAT IP Verification **");
        $display("** total test num = %2d **", scb.total_cnt);
        $display("** pass test num  = %2d **", scb.pass_cnt);
        $display("** fail test num  = %2d **", scb.fail_cnt);
        $display("**************************");

        $stop;
    endtask

endclass

module tb_uart_tx_sv ();

    uart_interface uart_if ();
    environment env;

    uart_tx_sv dut (
        .clk(uart_if.clk),
        .rst(uart_if.rst),
        .tx_start(uart_if.tx_start),  // start trigger
        .tx_data(uart_if.tx_data),
        .tx(uart_if.tx),
        .tx_busy(uart_if.tx_busy)
    );

    always #5 uart_if.clk = ~uart_if.clk;

    initial begin
        uart_if.clk = 0;
        uart_if.tx_start = 1;
        env = new(uart_if);
        env.run();
    end


endmodule
