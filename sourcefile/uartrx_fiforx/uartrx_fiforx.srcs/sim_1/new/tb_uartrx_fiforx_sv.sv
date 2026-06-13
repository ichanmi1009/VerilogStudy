`timescale 1ns / 1ps

class transaction;  

    rand bit [7:0] rx_data;
    bit      [7:0] pop_data;

    function debug_print(string name);
        if (name == "GEN" || name == "DRV") begin
            $display("%t : [%s] IN_RX_data = 0x%02h(%0d)", $time, name,
                     rx_data, rx_data);
        end else if (name == "MON") begin
            $display("%t : [%s] DUT_FIFO_RX_data = 0x%02h(%0d)", $time, name,
                     pop_data, pop_data);
        end
    
    endfunction

endclass

interface uart_fifo_interface;

    logic       clk;
    logic       rst;
    logic       rx;
    logic       pop;
    logic [7:0] pop_data;
    logic       full;
    logic       empty;

endinterface

class generator;

    transaction tr1, tr2;
    mailbox #(transaction) gen2drv_mbox;  
    mailbox #(transaction) gen2scb_mbox;
    event event_gen_next;  

    function new(mailbox#(transaction) gen2drv_mbox,
                 mailbox#(transaction) gen2scb_mbox, event event_gen_next);
   
        this.gen2drv_mbox   = gen2drv_mbox;
        this.gen2scb_mbox   = gen2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run(int count);
        repeat (count) begin 
            tr1 = new();
            tr1.randomize();

            tr2 = new();
            tr2.rx_data = tr1.rx_data;

            gen2scb_mbox.put(tr2);  
            gen2drv_mbox.put(tr1);  

            tr1.debug_print("GEN");
            @(event_gen_next);
        end
    endtask
endclass

class driver;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual uart_fifo_interface uart_vif;

    event event_gen_next;

    function new(mailbox#(transaction) gen2drv_mbox, event event_gen_next,
                 virtual uart_fifo_interface uart_vif);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.event_gen_next = event_gen_next;
        this.uart_vif       = uart_vif;
    endfunction

    task drive_byte(transaction tr);

        bit [9:0] uart_frame;

    
        //{stop_bit(1), tr.rx_data, start_bit(0)}
        uart_frame = {1'b1, tr.rx_data, 1'b0};
        for (int i = 0; i < 10; i++) begin
            uart_vif.rx = uart_frame[i];
            #104160;  // 9600bps
        end
     
        uart_vif.rx = 1;


    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            tr.debug_print("DRV");
            drive_byte(tr);
            ->event_gen_next;
        end
    endtask

    task pop_only(int count);
        repeat (count) begin
            wait (!uart_vif.empty);
            @(posedge uart_vif.clk);
            #1;
            uart_vif.pop = 1;
            @(posedge uart_vif.clk);
            #1;
            uart_vif.pop = 0;
        end
    endtask

    task preset();
        uart_vif.rst = 1;
        //uart_vif.rx  = 1;
        //uart_vif.pop = 0;

        repeat (2) @(posedge uart_vif.clk);
        uart_vif.rst = 0;
        repeat (10) @(posedge uart_vif.clk);

    endtask


endclass

class monitor;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox; 
    virtual uart_fifo_interface uart_vif;
    event event_gen_next;

    function new(mailbox#(transaction) mon2scb_mbox, event event_gen_next,
                 virtual uart_fifo_interface uart_vif);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.event_gen_next = event_gen_next;
        this.uart_vif       = uart_vif;
    endfunction

    task run();
        forever begin
            @(posedge uart_vif.clk);
            if (uart_vif.pop && !uart_vif.empty) begin
                tr = new();
                tr.pop_data = uart_vif.pop_data;
                mon2scb_mbox.put(tr);
                tr.debug_print("MON");
                ->event_gen_next;
            end

        end
    endtask


endclass

class scoreboard;

    mailbox #(transaction) mon2scb_mbox;  
    mailbox #(transaction) gen2scb_mbox;

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
        forever begin 
            gen2scb_mbox.get(tr_gen);
            mon2scb_mbox.get(tr_mon);
            tr_gen.debug_print("SCB");
            tr_mon.debug_print("SCB");

            total_cnt++;
            //pass fail
            if (tr_gen.rx_data == tr_mon.pop_data) begin
                pass_cnt++;
                $display(
                    "%t : PASS !! expected_pop_data = %d, got pop_data = %d",
                    $time, tr_gen.rx_data, tr_mon.pop_data);
            end else begin
                fail_cnt++;
                $display("%t : FAIL expected_pop_data = %d, got pop_data = %d",
                         $time, tr_gen.rx_data, tr_mon.pop_data);
            end
        end
    endtask
endclass


class environment;
    generator                   gen;
    driver                      drv;
    monitor                     mon;
    scoreboard                  scb;
    mailbox #(transaction)      gen2drv_mbox;
    mailbox #(transaction)      gen2scb_mbox;
    mailbox #(transaction)      mon2scb_mbox;
    event                       event_gen_next;

    virtual uart_fifo_interface uart_vif;

    int                         run_count;

    function new(virtual uart_fifo_interface uart_vif);
        gen2drv_mbox  = new;
        gen2scb_mbox  = new;
        mon2scb_mbox  = new;
        gen           = new(gen2drv_mbox, gen2scb_mbox, event_gen_next);
        drv           = new(gen2drv_mbox, event_gen_next, uart_vif);
        mon           = new(mon2scb_mbox, event_gen_next, uart_vif);
        scb           = new(mon2scb_mbox, gen2scb_mbox);

        this.uart_vif = uart_vif;
    endfunction



    task run();

        drv.preset();

        run_count = 16;

        fork
            gen.run(run_count);
            drv.run();
        join_any
        disable fork;
        wait (uart_vif.full);
        $display("PASS : FIFO FULL");


        fork
            drv.pop_only(run_count);
            mon.run();
            scb.run();
        join_any
        disable fork;

        wait (uart_vif.empty);
        $display("PASS : FIFO EMPTY");
        $display("%t : [ENV] ALL TASK END", $time);


        #20;
        $display("____________________________________");
        $display("** UART RX + FIFO RX Verification **");
        $display("** total test num = %13d **", scb.total_cnt);
        $display("** pass test num  = %13d **", scb.pass_cnt);
        $display("** fail test num  = %13d **", scb.fail_cnt);
        $display("************************************");

        $stop;
    endtask

endclass


module tb_uartrx_fiforx_sv ();

    uart_fifo_interface uart_fifo_if ();
    environment env;

    UARTRX_FIFORX dut (
        .clk     (uart_fifo_if.clk),
        .rst     (uart_fifo_if.rst),
        .rx      (uart_fifo_if.rx),
        .pop     (uart_fifo_if.pop),
        .pop_data(uart_fifo_if.pop_data),
        .full    (uart_fifo_if.full),
        .empty   (uart_fifo_if.empty)
    );

    always #5 uart_fifo_if.clk = ~uart_fifo_if.clk;

    initial begin
        uart_fifo_if.clk = 0;
        uart_fifo_if.rst = 1;
        uart_fifo_if.rx = 1;
        uart_fifo_if.pop = 0;
        env = new(uart_fifo_if);
        env.run();
    end

endmodule
