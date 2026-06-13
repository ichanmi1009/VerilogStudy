`timescale 1ns / 1ps

class transaction;
    rand bit [7:0] addr;
    rand bit [7:0] wdata;
    rand bit       we;
    bit      [7:0] rdata;
endclass

interface ram_interface (
    input logic clk
);
    logic we;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;
endinterface

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event event_scb_next;

    function new(mailbox#(transaction) gen2drv_mbox, event event_scb_next);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.event_scb_next = event_scb_next;
    endfunction

    task random(int loop);
        repeat (loop) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            @(event_scb_next);
        end
    endtask

    task run();
        for (int i = 0; i < 256; i++) begin
            tr = new();
            tr.randomize();
            tr.we   = 1'b1;
            tr.addr = i;
            gen2drv_mbox.put(tr);
            @(event_scb_next);
        end

        for (int i = 0; i < 256; i++) begin
            tr = new();
            tr.we = 1'b0;
            tr.addr = i;
            gen2drv_mbox.put(tr);
            @(event_scb_next);
        end
    endtask

endclass

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual ram_interface ram_vif;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual ram_interface ram_vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.ram_vif = ram_vif;
    endfunction

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            // drive timing negedge + #4
            @(negedge ram_vif.clk);
            #4;
            ram_vif.we    = tr.we;
            ram_vif.addr  = tr.addr;
            ram_vif.wdata = tr.wdata;
        end
    endtask

endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual ram_interface ram_vif;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual ram_interface ram_vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.ram_vif = ram_vif;
    endfunction

    task run();
        forever begin
            // monitor timing posedge + #1
            @(posedge ram_vif.clk);
            #1;
            tr       = new();
            tr.we    = ram_vif.we;
            tr.addr  = ram_vif.addr;
            tr.wdata = ram_vif.wdata;
            tr.rdata = ram_vif.rdata;
            mon2scb_mbox.put(tr);
        end
    endtask

endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event event_scb_next;

    bit [7:0] memory[255:0];

    function new(mailbox#(transaction) mon2scb_mbox, event event_scb_next);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.event_scb_next = event_scb_next;
    endfunction

    int pass, fail;

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            if (tr.we) begin
                memory[tr.addr] = tr.wdata;
            end else begin
                if (tr.rdata == memory[tr.addr]) begin
                    pass++;
                    $display(
                        "[%0t] PASS : wdata(expected) : %0h, rdata(actual) : %0h",
                        $time, memory[tr.addr], tr.rdata);
                end else begin
                    fail++;
                    $display(
                        "[%0t] FAIL : wdata(expected) : %0h, rdata(actual) : %0h",
                        $time, memory[tr.addr], tr.rdata);
                end
            end
            ->event_scb_next;
        end
    endtask

endclass

class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    event event_scb_next;

    function new(virtual ram_interface ram_vif);
        gen2drv_mbox = new;
        mon2scb_mbox = new;
        gen = new(gen2drv_mbox, event_scb_next);
        drv = new(gen2drv_mbox, ram_vif);
        mon = new(mon2scb_mbox, ram_vif);
        scb = new(mon2scb_mbox, event_scb_next);
    endfunction

    task run();

        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_any



        #10;

        $display("_________________________________________");
        $display("**     RAM WRITE/READ Verification     **");
        $display("** total test num = %18d **", scb.pass + scb.fail);
        $display("** pass test num  = %18d **", scb.pass);
        $display("** fail test num  = %18d **", scb.fail);
        $display("_________________________________________");
        $stop;

        #10;

        scb.pass = 0;
        scb.fail = 0;

        gen.random(500);

        $display("_____________________________________");
        $display("**     RAM RANDOM Verification     **");
        $display("** total test num = %14d **", scb.pass + scb.fail);
        $display("** pass test num  = %14d **", scb.pass);
        $display("** fail test num  = %14d **", scb.fail);
        $display("_____________________________________");
        $stop;

    endtask

endclass

module tb_ram_sv ();

    logic clk;

    ram_interface ram_if (clk);
    environment env;

    ram dut (
        .clk(ram_if.clk),
        .we(ram_if.we),
        .addr(ram_if.addr),
        .wdata(ram_if.wdata),
        .rdata(ram_if.rdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        env = new(ram_if);
        env.run();
    end

endmodule
