`timescale 1ns / 1ps
class transaction;

    rand bit       push;
    rand bit       pop;
    rand bit [7:0] push_data;
    bit      [7:0] pop_data;
    // bit            rst;
    bit            full;
    bit            empty;


    constraint push_pop {
        push dist {
            1 :/ 70,
            0 :/ 30
        };
        pop dist {
            1 :/ 70,
            0 :/ 30
        };
    }

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
    mailbox #(transaction) gen2drv_mbox;
    event event_gen_next;

    function new(mailbox#(transaction) gen2drv_mbox, event event_gen_next);

        this.gen2drv_mbox   = gen2drv_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run(int count);
        repeat (count) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            tr.debug_print("GEN");
            @(event_gen_next);
        end
    endtask

    task run_push(int count);
        repeat (count) begin
            tr = new();
            tr.randomize();
            tr.push = 1;
            tr.pop  = 0;
            gen2drv_mbox.put(tr);
            @(event_gen_next);
        end
    endtask


    task run_pop(int count);
        repeat (count) begin
            tr = new();
            tr.randomize();
            tr.push = 0;
            tr.pop  = 1;
            gen2drv_mbox.put(tr);
            @(event_gen_next);
        end
    endtask


endclass

class driver;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event event_gen_next;
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

        @(negedge fifo_vif.clk);
        // assertion check full, empty
        assert (fifo_vif.empty) $display("[DRV Assert] reset pass : empty!");
        else $display("[DRV Assert] reset fail : empty = %d", fifo_vif.empty);

        assert (!fifo_vif.full) $display("[DRV Assert] reset pass : full!");
        else $display("[DRV Assert] reset fail : full = %d", fifo_vif.full);

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

            $display(
                "%t : [DRV] push = %d, pop = %d, push_data = %d, full = %d, empty = %d",
                $time, fifo_vif.push, fifo_vif.pop, fifo_vif.push_data,
                fifo_vif.full, fifo_vif.empty);

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
            $display(
                "%t : [DRV] push = %d, pop = %d, pop_data = %d, full = %d, empty = %d",
                $time, fifo_vif.push, fifo_vif.pop, fifo_vif.pop_data,
                fifo_vif.full, fifo_vif.empty);

            ->event_gen_next;
        end
    endtask



    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(posedge fifo_vif.clk);
            #1;
            fifo_vif.push = tr.push;
            fifo_vif.push_data = tr.push_data;
            fifo_vif.pop = tr.pop;
            $display(
                "%t : [DRV] push = %d, pop = %d, push_data = %d, pop_data = %d, full = %d, empty = %d",
                $time, fifo_vif.push, fifo_vif.pop, fifo_vif.push_data,
                fifo_vif.pop_data, fifo_vif.full, fifo_vif.empty);
        end
    endtask
endclass

class monitor;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
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
    mailbox #(transaction) mon2scb_mbox;
    event event_gen_next;

    bit [7:0] fifo_que[$:16];
    bit [7:0] compare_data;

    //pass,fail count
    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;

    function new(mailbox#(transaction) mon2scb_mbox, event event_gen_next);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run();
        forever begin  // event 추�??
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



    task run();

        // ram interface initial
        // reset test by assertion
        drv.preset();


        // push only test for full signal "1"
        run_count = 16;
        fork
            gen.run_push(run_count);
            drv.push_only(run_count);
        join
        $display("%t : [ENV] PUSH_ONLY TASK END", $time);
        #10;

        assert (fifo_vif.full)
            $display("[DRV Assert] FIFO FULL, PASS : push only 16 time test");
        else
            $display(
                "[DRV Assert] FIFO NOT FULL = %d, FAIL: push only test",
                fifo_vif.full
            );

        //if (fifo_vif.full) $display("PASS : push only 16 time test, FIFO FULL");
        //else $display("FAIL: push only test");

        fork
            gen.run_pop(run_count);
            drv.pop_only(run_count);
        join
        $display("%t : [ENV] POP_ONLY TASK END", $time);
        #10;

        assert (fifo_vif.empty)
            $display("[DRV Assert] FIFO EMPTY, PASS : pop only 16 time test");
        else
            $display(
                "[DRV Assert] FIFO NOT EMPTY = %d, FAIL: pop only test",
                fifo_vif.empty
            );

        fork
            gen.run(500);
            drv.run();
            mon.run();
            scb.run();
        join_any
        disable fork;

        $display("fifo Constraint random test end");
        $display("%t : [ENV] ALL TASK END", $time);


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

    fifo_interface fifo_if ();
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

