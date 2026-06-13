`timescale 1ns / 1ps

class transaction_rx;

    rand bit [7:0] in_rx_data;
    bit            rx;
    bit      [7:0] rx_data;
    bit            rx_done;

    function debug_print(string name);
        if (name == "GEN" || name == "DRV") begin
            $display("%t : [%s] IN_RX_data = 0x%02h(%0d)", $time, name,
                     in_rx_data, in_rx_data);
        end else if (name == "MON") begin
            $display("%t : [%s] rx_done = %0b, DUT RX Complete", $time, name,
                     rx_done);
            $display("%t : [%s] DUT_RX_data = 0x%02h(%0d)", $time, name,
                     rx_data, rx_data);
        end else begin
            $display("%t : [%s] Expected_data = %d, RX_data = %d", $time, name,
                     in_rx_data, rx_data);
        end
        $display("%t : [%s] in_rx_data = %d, out_rx_data = %d", $time, name,
                 in_rx_data, rx_data);
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
    mailbox #(transaction_rx) gen2drv_mbox;
    mailbox #(transaction_rx) gen2scb_mbox;
    event event_gen_next;

    function new(mailbox#(transaction_rx) gen2drv_mbox,
                 mailbox#(transaction_rx) gen2scb_mbox, event event_gen_next);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.gen2scb_mbox   = gen2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run(int count);
        repeat (count) begin
            tr1 = new();
            tr1.randomize();

            tr2 = new();
            tr2.in_rx_data = tr1.in_rx_data;

            gen2scb_mbox.put(tr2);
            gen2drv_mbox.put(tr1);

            tr1.debug_print("GEN");
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

        bit [9:0] uart_frame;

        //{stop_bit(1), tr.in_rx_data, start_bit(0)}
        uart_frame = {1'b1, tr.in_rx_data, 1'b0};
        $display("%t : [DRV] Data drive start[LSB] : uart_frame = 10'b%010b",
                 $time, uart_frame);
        for (int i = 0; i < 10; i++) begin
            uart_vif.rx = uart_frame[i];
            if (i == 0) begin
                $display("%t : [DRV] START bit : %0b", $time, uart_frame[i]);
            end else if (i == 9) begin
                $display("%t : [DRV] DATA bit[0:7] = 0x%02h(%0d)", $time,
                         tr.in_rx_data, tr.in_rx_data);
                $display("%t : [DRV] STOP bit : %0b", $time, uart_frame[i]);
            end else
                $display(
                    "%t : [DRV] DATA bit[%0d] : %0b",
                    $time,
                    i - 1,
                    uart_frame[i]
                );
            #104160;  // 9600bps
        end
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
        repeat (2) @(posedge uart_vif.clk);
        uart_vif.rst = 0;

        @(negedge uart_vif.clk);
        // assertion check
        assert (uart_vif.rx == 1) $display("[DRV Assert] reset pass : rx = 1");
        else $display("[DRV Assert] reset fail : rx = %0b", uart_vif.rx);

        assert (uart_vif.rx_data == 8'h00)
            $display("[DRV Assert] reset pass : rx_data = 0x00");
        else
            $display(
                "[DRV Assert] reset fail : rx_data = 0x%02h", uart_vif.rx_data
            );

        assert (uart_vif.rx_done == 0)
            $display("[DRV Assert] reset pass : rx_done = 0");
        else
            $display(
                "[DRV Assert] reset fail : rx_done = %0b", uart_vif.rx_done
            );

    endtask



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

    mailbox #(transaction_rx) mon2scb_mbox;
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
                    "%t : [SCB] PASS !! Expected = 0x%02h(%0d), GOT Rx_data = 0x%02h(%0d)",
                    $time, tr_gen.in_rx_data, tr_gen.in_rx_data,
                    tr_mon.rx_data, tr_mon.rx_data);
            end else begin
                fail_cnt++;
                $display(
                    "%t : [SCB] FAIL Expected = 0x%02h(%0d), GOT Rx_data = 0x%02h(%0d)",
                    $time, tr_gen.in_rx_data, tr_gen.in_rx_data,
                    tr_mon.rx_data, tr_mon.rx_data);
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



    task run();

        drv.preset();

        fork
            gen.run(500);
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

module tb_uart_rx ();

    uart_interface_rx uart_if ();
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
