`timescale 1ns / 1ps

class transaction; 

    rand bit [7:0] rx_data;
    bit      [7:0] tx_data;
    

    constraint non_zero {
        rx_data != 0;  
    }

    function debug_print(string name);
        if (name == "GEN" || name == "DRV") begin
            $display("%t : [%s] RX_data = 0x%02h(%0d)", $time, name, rx_data,
                     rx_data);
        end else if (name == "MON") begin
            $display("%t : [%s] TX_data = 0x%02h(%0d)", $time, name, tx_data,
                     tx_data);
        end else begin
            $display("%t : [%s] RX_data = 0x%02h(%0d), TX_data = 0x%02h(%0d)",
                     $time, name, rx_data, rx_data, tx_data, tx_data);
        end
    endfunction

endclass

interface uart_fifo_interface;

    logic clk;
    logic rst;
    logic rx;
    logic tx;

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

    task run_sequence();
        for (int i = 1; i <= 16; i++) begin
            tr1 = new();
            tr1.rx_data = i;
            tr2 = new();
            tr2.rx_data = tr1.rx_data;
            gen2scb_mbox.put(tr2);
            gen2drv_mbox.put(tr1);
            tr1.debug_print("GEN");
            @(event_gen_next);
        end
    endtask

    task run_boundary();
        bit [7:0] boundary[4] = '{8'hFF, 8'h55, 8'hAA, 8'h00};
        foreach (boundary[i]) begin
            tr1 = new();
            tr1.rx_data = boundary[i];
            tr2 = new();
            tr2.rx_data = boundary[i];
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


    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual uart_fifo_interface uart_vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.uart_vif     = uart_vif;
    endfunction

    task drive_byte(transaction tr);

        bit [9:0] uart_frame;

        
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
        end
    endtask


    task preset();
        uart_vif.rst = 1;

        repeat (2) @(posedge uart_vif.clk);
        uart_vif.rst = 0;

        @(negedge uart_vif.clk);
        // assertion check
        assert (uart_vif.rx == 1)
            $display("[DRV Assert] reset pass : rx = 1 (idle)");
        else $display("[DRV Assert] reset fail : rx = %0b", uart_vif.rx);
        assert (uart_vif.tx == 1)
            $display("[DRV Assert] reset pass : tx = 1 (idle)");
        else $display("[DRV Assert] reset fail : tx = %0b", uart_vif.tx);



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
        bit [7:0] collected_data;
        time previous_time;
        time BAUD_PERIOD;

        forever begin

            @(negedge uart_vif.tx);
            $display("%t : [MON] Start bit detected (tx=0)", $time);


            #(104160 / 2);
            collected_data = 8'h00;
            previous_time  = $time;

            // DATA
            for (int i = 0; i < 8; i++) begin
                #104160;
                collected_data[i] = uart_vif.tx;
                BAUD_PERIOD = $time - previous_time;
                previous_time = $time;

                if (BAUD_PERIOD == 104160) begin
                    $display(
                        "%t : [MON] Sampling bit at center : DATA_bit[%0d] = %d[8'b%08b], BAUD_PERIOD PASS : %0dns",
                        $time, i, uart_vif.tx, collected_data, BAUD_PERIOD);
                end else begin
                    $display(
                        "%t : [MON] Sampling bit at center : DATA_bit[%0d] = %d[8'b%08b], BAUD_PERIOD FAIL : %0dns",
                        $time, i, uart_vif.tx, collected_data, BAUD_PERIOD);
                end
            end

            #104160;
            if (uart_vif.tx == 1) begin
                $display("%t : [MON] Stop bit detected (tx=1)", $time);
                tr = new();
                tr.tx_data = collected_data;

                mon2scb_mbox.put(tr);
                tr.debug_print("MON");
            end else begin
                $display("%t : [MON] STOP bit error (tx=0)", $time);
            end
            ->event_gen_next;

        end
    endtask
endclass

class scoreboard;

    mailbox #(transaction) gen2scb_mbox;
    mailbox #(transaction) mon2scb_mbox; 

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
            if (tr_gen.rx_data == tr_mon.tx_data) begin
                pass_cnt++;
                $display(
                    "%t : [SCB] PASS !! expected_data = %d, got tx_data = %d",
                    $time, tr_gen.rx_data, tr_mon.tx_data);
            end else begin
                fail_cnt++;
                $display("%t : [SCB] FAIL expected_data = %d, got tx_data = %d",
                         $time, tr_gen.rx_data, tr_mon.tx_data);
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

    function new(virtual uart_fifo_interface uart_vif);
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

        // ram interface initial
        // reset test by assertion
        drv.preset();

       
        $display("uart loopback Constraint random test");
        fork
            gen.run(500);
            drv.run();
            mon.run();
            scb.run();
        join_any
        disable fork;

        $display("%t : [ENV] RANDOM TASK END", $time);

        #20;

      
        $display("sequence 1~16 test");
        fork
            gen.run_sequence();
            drv.run();
            mon.run();
            scb.run();
        join_any
        disable fork;

        $display("%t : [ENV] SEQUENCE TASK END", $time);

        #20;

        
        $display("Boundry (FF, 55, AA, 00)");
        fork
            gen.run_boundary();
            drv.run();
            mon.run();
            scb.run();
        join_any
        disable fork;

        $display("%t : [ENV] BOUNDARY TASK END", $time);
        $display("%t : [ENV] ALL TASK END", $time);

        #20;
        $display("_____________________________");
        $display("**  URAT FIFO Verification **");
        $display("**  total test num = %3d   **", scb.total_cnt);
        $display("**  pass test num  = %3d   **", scb.pass_cnt);
        $display("**  fail test num  = %3d   **", scb.fail_cnt);
        $display("*****************************");


        $stop;
    endtask

endclass

module tb_uart_fifo_sv ();

    uart_fifo_interface uart_if ();
    environment env;

    uart_fifo dut (
        .clk(uart_if.clk),
        .rst(uart_if.rst),
        .rx (uart_if.rx),
        .tx (uart_if.tx)
    );

    always #5 uart_if.clk = ~uart_if.clk;

    initial begin
        uart_if.clk = 0;
        uart_if.rx = 1;
        env = new(uart_if);
        env.run();
    end

endmodule
