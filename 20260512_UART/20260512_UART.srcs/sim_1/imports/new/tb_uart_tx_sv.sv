`timescale 1ns / 1ps

class transaction_tx;  // transaction이므로 bit로 선언 logic 필요 없음

    rand bit [7:0] tx_data;
    bit      [7:0] out_tx_data;
    // bit            tx_start; : data 보낼려면 tx_start가 1이어야 하니까 랜덤으로 보낼 필요 없음

    function debug_print(string name);
        if (name == "GEN" || name == "DRV") begin
            $display("%t : [%s] IN_TX_data = 0x%02h(%0d)", $time, name,
                     tx_data, tx_data);
        end else if (name == "MON") begin
            $display("%t : [%s] DUT_TX_data = 0x%02h(%0d)", $time, name,
                     out_tx_data, out_tx_data);
        end
    endfunction

endclass

interface uart_interface_tx;

    logic       clk;
    logic       rst;
    logic       tx_start;
    logic [7:0] tx_data;
    // logic       b_tick;
    logic       tx;
    logic       tx_busy;

endinterface

class generator_tx;

    transaction_tx tr1, tr2;
    mailbox #(transaction_tx) gen2drv_mbox;  // 데이터 타입 transaction
    mailbox #(transaction_tx) gen2scb_mbox;
    event event_gen_next;  //monitor에서 오는 event

    function new(mailbox#(transaction_tx) gen2drv_mbox,
                 mailbox#(transaction_tx) gen2scb_mbox, event event_gen_next);
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
            @(event_gen_next);
        end
    endtask
endclass

class driver_tx;


    transaction_tx tr;
    mailbox #(transaction_tx) gen2drv_mbox;
    virtual uart_interface_tx uart_vif;


    function new(mailbox#(transaction_tx) gen2drv_mbox,
                 virtual uart_interface_tx uart_vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.uart_vif     = uart_vif;
    endfunction

    task drive_byte(transaction_tx tr);
        // tx_start와 tx_data는 내부에 동기화된 신호여서 상승엣지 후 1n에 드라이브
        @(posedge uart_vif.clk);
        #1;
        uart_vif.tx_data  = tr.tx_data;
        uart_vif.tx_start = 1;
        #10;
        uart_vif.tx_start = 0;
        @(negedge uart_vif.tx_busy);
        //tx_data, tx_start만 drive

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
        uart_vif.tx_start = 0;
        uart_vif.tx_data = 0;

        repeat (2) @(posedge uart_vif.clk);
        uart_vif.rst = 0;

        @(negedge uart_vif.clk);
        // assertion check
        assert (uart_vif.tx == 1) $display("[DRV Assert] reset pass : tx = 1");
        else $display("[DRV Assert] reset fail : tx = %0b", uart_vif.tx);

        // tx_busy 확인
        assert (uart_vif.tx_busy == 0)
            $display("[DRV Assert] reset pass : tx_busy = 0");
        else
            $display(
                "[DRV Assert] reset fail : tx_busy = %0b", uart_vif.tx_busy
            );

    endtask


endclass

class monitor_tx;

    transaction_tx tr;
    mailbox #(transaction_tx) mon2scb_mbox;  // 데이터 타입 transaction
    virtual uart_interface_tx uart_vif;
    event event_gen_next;

    function new(mailbox#(transaction_tx) mon2scb_mbox, event event_gen_next,
                 virtual uart_interface_tx uart_vif);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.event_gen_next = event_gen_next;
        this.uart_vif       = uart_vif;
    endfunction

    // 정밀한 타이밍으로 신호를 관찰
    task run();

        bit [7:0] collected_data;
        forever begin
            @(posedge uart_vif.tx_busy);
            @(negedge uart_vif.tx);

            #(104160 / 2);

            // DATA
            for (int i = 0; i < 8; i++) begin
                #104160;
                collected_data[i] = uart_vif.tx;
                $display("%t : [MON] Sampling bit at center : value = %d",
                         $time, uart_vif.tx);
            end

            #104160;
            if (uart_vif.tx == 1) begin
                tr = new();
                tr.out_tx_data = collected_data;

                mon2scb_mbox.put(tr);
                tr.debug_print("MON");
            end else begin
                $display("%t : [MON] uart frame fail (STOP bit error)", $time);
            end

            ->event_gen_next;
        end
    endtask


endclass

class scoreboard_tx;

    mailbox #(transaction_tx) gen2scb_mbox;
    mailbox #(transaction_tx) mon2scb_mbox;  // 데이터 타입 transaction

    bit [7:0] compare_data;

    //pass,fail count
    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;

    function new(mailbox#(transaction_tx) mon2scb_mbox,
                 mailbox#(transaction_tx) gen2scb_mbox);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
    endfunction

    task run();
        transaction_tx tr_gen, tr_mon;
        forever begin  // event 추가?
            gen2scb_mbox.get(tr_gen);
            mon2scb_mbox.get(tr_mon);
            tr_gen.debug_print("SCB");
            tr_mon.debug_print("SCB");

            total_cnt++;
            //pass fail
            if (tr_gen.tx_data == tr_mon.out_tx_data) begin
                pass_cnt++;
                $display(
                    "%t : [SCB] PASS !! Expected = 0x%02h(%0d), GOT Tx_data = 0x%02h(%0d)",
                    $time, tr_gen.tx_data, tr_gen.tx_data, tr_mon.out_tx_data,
                    tr_mon.out_tx_data);
            end else begin
                fail_cnt++;
                $display(
                    "%t : [SCB] FAIL Expected = 0x%02h(%0d), GOT Tx_data = 0x%02h(%0d)",
                    $time, tr_gen.tx_data, tr_gen.tx_data, tr_mon.out_tx_data,
                    tr_mon.out_tx_data);
            end
        end
    endtask
endclass


class environment_tx;
    generator_tx              gen;
    driver_tx                 drv;
    monitor_tx                mon;
    scoreboard_tx             scb;
    mailbox #(transaction_tx) gen2drv_mbox;
    mailbox #(transaction_tx) gen2scb_mbox;
    mailbox #(transaction_tx) mon2scb_mbox;
    event                     event_gen_next;

    virtual uart_interface_tx uart_vif;

    int                       run_count;

    function new(virtual uart_interface_tx uart_vif);
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
            gen.run(500);
            drv.run();
            mon.run();
            scb.run();
        join_any

        $display("uart tx Constraint random test end");
        $display("%t : [ENV] ALL TASK END", $time);
        // 조합출력 : 15, 순차출력 : 16 이거 아니엇음

        #20;
        $display("__________________________");
        $display("** UART Verification **");
        $display("** total test num = %2d **", scb.total_cnt);
        $display("** pass test num  = %2d **", scb.pass_cnt);
        $display("** fail test num  = %2d **", scb.fail_cnt);
        $display("**************************");

        $stop;
    endtask

endclass

module tb_uart_tx_sv ();

    uart_interface_tx uart_if ();
    environment_tx env;

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
        env = new(uart_if);
        env.run();
    end


endmodule
