`timescale 1ns / 1ps

class transaction_rx;  // transaction이므로 bit로 선언 logic 필요 없음

    rand bit [7:0] in_rx_data;
    bit            rx;
    bit      [7:0] rx_data;
    bit            rx_done;

    function debug_print(string name);
        if (name == "GEN" || name == "DRV") begin
            $display("%t : [%s] IN_RX_data = 0x%02h(%0d)", $time, name,
                     in_rx_data, in_rx_data);
        end else if (name == "MON") begin
            $display("%t : [%s] DUT_RX_data = 0x%02h(%0d)", $time, name,
                     rx_data, rx_data);
        end
        //end else begin
        //    $display("%t : [%s] Expected_data = %d, RX_data = %d", $time, name,
        //             in_rx_data, rx_data);
        //end
        //$display("%t : [%s] in_rx_data = %d, out_rx_data = %d", $time, name,
        //in_rx_data, rx_data);
    endfunction

endclass

interface uart_interface_rx;

    logic       clk;
    logic       rst;
    logic       rx;
    logic [7:0] rx_data;
    logic       rx_done;

endinterface

class generator_rx;

    transaction_rx tr1, tr2;
    mailbox #(transaction_rx) gen2drv_mbox;  // 데이터 타입 transaction
    mailbox #(transaction_rx) gen2scb_mbox;
    event event_gen_next;  //monitor에서 오는 event

    function new(mailbox#(transaction_rx) gen2drv_mbox,
                 mailbox#(transaction_rx) gen2scb_mbox, event event_gen_next);
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
            tr2.in_rx_data = tr1.in_rx_data;

            gen2scb_mbox.put(tr2);  // 스코어보드용 tr
            gen2drv_mbox.put(tr1);  // 드라이브용 tr

            tr1.debug_print("GEN");
            //tr2.debug_print("GEN");
            @(event_gen_next);
        end
    endtask
endclass

class driver_rx;

    transaction_rx tr;
    mailbox #(transaction_rx) gen2drv_mbox;
    virtual uart_interface_rx uart_vif;


    function new(mailbox#(transaction_rx) gen2drv_mbox,
                 virtual uart_interface_rx uart_vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.uart_vif     = uart_vif;
    endfunction

    task drive_byte(transaction_rx tr);

        // rx 신호는 클럭이랑 관계없이 
        // baud rate 속도에 맞춰서
        // 1비트씩 104160ns 간격으로 drive

        // dut 내부 b_tick이 알아서 비트 중간 지점에서 샘플링




        bit [9:0] uart_frame;

        // DATA 전송 상태
        //{stop_bit(1), tr.in_rx_data, start_bit(0)}
        uart_frame = {1'b1, tr.in_rx_data, 1'b0};
        for (int i = 0; i < 10; i++) begin
            uart_vif.rx = uart_frame[i];
            #104160;  // 9600bps
        end
        // IDLE 상태
        uart_vif.rx = 1;


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
        //uart_vif.rx  = 1;
        repeat (2) @(posedge uart_vif.clk);
        uart_vif.rst = 0;

        @(negedge uart_vif.clk);
        // assertion check
        assert (uart_vif.rx == 1)
            $display("[DRV Assert] rx idle pass : rx = 1");
        else $display("[DRV Assert] rx idle fail : rx = %0b", uart_vif.rx);

        // rx_data 초기화 확인

        
        assert (uart_vif.rx_data == 8'h00)
            $display("[DRV Assert] rx_data reset pass : rx_data = 0x00");
        else
            $display(
                "[DRV Assert] rx_data reset fail : rx_data = 0x%02h",
                uart_vif.rx_data
            );
    endtask

    //repeat (10) @(posedge uart_vif.clk);



endclass

class monitor_rx;

    transaction_rx tr;
    mailbox #(transaction_rx) mon2scb_mbox;
    virtual uart_interface_rx uart_vif;
    event event_gen_next;

    function new(mailbox#(transaction_rx) mon2scb_mbox, event event_gen_next,
                 virtual uart_interface_rx uart_vif);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.event_gen_next = event_gen_next;
        this.uart_vif       = uart_vif;
    endfunction

    task run();
        forever begin
            @(posedge uart_vif.rx_done);
            @(negedge uart_vif.clk);
            tr         = new();
            tr.rx_data = uart_vif.rx_data;
            tr.rx_done = uart_vif.rx_done;
            mon2scb_mbox.put(tr);
            tr.debug_print("MON");
            ->event_gen_next;
        end
    endtask


endclass

class scoreboard_rx;

    mailbox #(transaction_rx) mon2scb_mbox;  // 데이터 타입 transaction
    mailbox #(transaction_rx) gen2scb_mbox;

    bit [7:0] compare_data;

    //pass,fail count
    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;

    function new(mailbox#(transaction_rx) mon2scb_mbox,
                 mailbox#(transaction_rx) gen2scb_mbox);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
    endfunction

    task run();
        transaction_rx tr_gen, tr_mon;
        forever begin
            gen2scb_mbox.get(tr_gen);
            mon2scb_mbox.get(tr_mon);
            tr_gen.debug_print("SCB");
            tr_mon.debug_print("SCB");

            total_cnt++;
            //pass fail
            if (tr_gen.in_rx_data == tr_mon.rx_data) begin
                pass_cnt++;
                $display(
                    "%t : PASS !! Expected = 0x%02h(%0d), GOT Rx_data = 0x%02h(%0d), Rx_done = %0d",
                    $time, tr_gen.in_rx_data, tr_gen.in_rx_data,
                    tr_mon.rx_data, tr_mon.rx_data, tr_mon.rx_done);
            end else begin
                fail_cnt++;
                $display(
                    "%t : FAIL Expected = 0x%02h(%0d), GOT Rx_data = 0x%02h(%0d), Rx_done = %0d",
                    $time, tr_gen.in_rx_data, tr_gen.in_rx_data,
                    tr_mon.rx_data, tr_mon.rx_data, tr_mon.rx_done);
            end
        end
    endtask
endclass


class environment_rx;
    generator_rx              gen;
    driver_rx                 drv;
    monitor_rx                mon;
    scoreboard_rx             scb;
    mailbox #(transaction_rx) gen2drv_mbox;
    mailbox #(transaction_rx) gen2scb_mbox;
    mailbox #(transaction_rx) mon2scb_mbox;
    event                     event_gen_next;

    virtual uart_interface_rx uart_vif;

    int                       run_count;

    function new(virtual uart_interface_rx uart_vif);
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

        drv.preset();

        fork
            gen.run(50);
            drv.run();
            mon.run();
            scb.run();
        join_any
        $display("uart rx Constraint random test end");
        $display("%t : [ENV] ALL TASK END", $time);

        #20;
        $display("__________________________");
        $display("** UART RX Verification **");
        $display("** total test num = %2d **", scb.total_cnt);
        $display("** pass test num  = %2d **", scb.pass_cnt);
        $display("** fail test num  = %2d **", scb.fail_cnt);
        $display("**************************");

        $stop;
    endtask

endclass

module tb_uart_rx_sv ();

    uart_interface_rx uart_if ();  // 괄호 빼먹음 추가함
    environment_rx env;

    uart_rx_sv dut (
        .clk(uart_if.clk),
        .rst(uart_if.rst),
        .rx(uart_if.rx),
        .rx_data(uart_if.rx_data),
        .rx_done(uart_if.rx_done)
    );

    always #5 uart_if.clk = ~uart_if.clk;

    initial begin
        uart_if.clk = 0;
        //uart_if.rst = 1;
        uart_if.rx = 1;
        env = new(uart_if);
        env.run();
    end


endmodule
