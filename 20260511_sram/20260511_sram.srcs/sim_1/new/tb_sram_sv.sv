`timescale 1ns / 1ps

class transaction;
    rand bit [7:0] addr;
    rand bit [7:0] wdata;
    rand bit       we;
    bit      [7:0] rdata;


    function void debug_print(string name);
        $display("%t : [%s] addr = %d, wdata = %d, we = %d, rdata = %d", $time,
                 name, addr, wdata, we, rdata);
    endfunction

endclass

interface reg_interface;
    logic       clk;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic       we;
    logic [7:0] rdata;
endinterface

class generator;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;  // 데이터 타입 transaction
    event event_gen_next;  //score board에서 오는 event

    function new(mailbox#(transaction) gen2drv_mbox, event event_gen_next);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run(int count);
        repeat (count) begin
            tr = new();
            tr.randomize();
            tr.debug_print("GEN");
            gen2drv_mbox.put(tr);
            @(event_gen_next);
        end
    endtask

endclass

class driver;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;  // 데이터 타입 transaction
    event event_mon_next;
    virtual reg_interface reg_vif;

    function new(mailbox#(transaction) gen2drv_mbox, event event_mon_next,
                 virtual reg_interface reg_vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.event_mon_next = event_mon_next;
        this.reg_vif = reg_vif;
    endfunction

    task run();
        forever begin
            // 상승엣지
            @(posedge reg_vif.clk);
            #1;
            gen2drv_mbox.get(tr);  // 왜?
            reg_vif.addr = tr.addr;
            reg_vif.wdata = tr.wdata;
            reg_vif.we = tr.we;
            tr.debug_print("DRV");
            // event 언제 발생시킬까? 10n?, event 잘못 날리면 race condition 발생
            // @(posedge reg_vif.clk); 해버리면 2사이클 날릴수도
            // negative?

            @(negedge reg_vif.clk);
            ->event_mon_next;
            // -> event를 발생 시켜라는 의미(#4 이후)
        end
    endtask

endclass

class monitor;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;  // 데이터 타입 transaction
    event event_mon_next;
    virtual reg_interface reg_vif;

    function new(mailbox#(transaction) mon2scb_mbox, event event_mon_next,
                 virtual reg_interface reg_vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.event_mon_next = event_mon_next;
        this.reg_vif = reg_vif;
    endfunction

    task run();
        forever begin
            @(event_mon_next);
            @(posedge reg_vif.clk);
            tr = new();
            tr.addr = reg_vif.addr;
            tr.wdata = reg_vif.wdata;
            tr.we = reg_vif.we;
            #1;
            tr.rdata = reg_vif.rdata;
            tr.debug_print("MON");
            mon2scb_mbox.put(tr);
        end
    endtask


endclass


class scoreboard;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;  // 데이터 타입 transaction
    event event_gen_next;  //score board에서 오는 event
    logic [7:0] register[0:256];

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

            if (tr.we) begin
                register[tr.addr] = tr.wdata;
                $display("%t : addr = %d, wdata = %d!", $time, tr.addr,
                         tr.wdata);
            end else begin
                if (register[tr.addr] == tr.rdata) begin
                    pass_cnt++;
                    $display("%t : PASS !! addr = %d, rdata = %d", $time,
                             tr.addr, tr.rdata);
                end else begin
                    fail_cnt++;
                    $display("%t : FAIL !! addr = %d, rdata = %d", $time,
                             tr.addr, tr.rdata);
                end
            end
            ->event_gen_next;
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

    event event_gen_next;
    event event_mon_next;

    function new(virtual reg_interface reg_vif);
        gen2drv_mbox = new;
        mon2scb_mbox = new;
        gen          = new(gen2drv_mbox, event_gen_next);
        drv          = new(gen2drv_mbox, event_mon_next, reg_vif);
        mon          = new(mon2scb_mbox, event_mon_next, reg_vif);
        scb          = new(mon2scb_mbox, event_gen_next);
    endfunction

    //fork join_any 적용

    task run();
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any
        $display("%t : ENV for join_any end", $time);
        #20;
        $display("________________________________");
        $display("** Register 8bit verification **");
        $display("**** total test number = %4d **", scb.total_cnt);
        $display("**** pass test number = %4d **", scb.pass_cnt);
        $display("**** fail test number = %4d **", scb.fail_cnt);
        $display("*******************************");
        $stop;
    endtask

endclass



module tb_sram_sv ();

    reg_interface reg_if ();  // 괄호 빼먹음 추가함
    environment env;

    sram_8 dut (
        .clk(reg_if.clk),
        .addr(reg_if.addr),
        .wdata(reg_if.wdata),
        .we(reg_if.we),
        .rdata(reg_if.rdata)
    );

    always #5 reg_if.clk = ~reg_if.clk;

    initial begin
        reg_if.clk = 0;
        //reset 제어는 drive에서 수행, d, q도
        env = new(reg_if);
        env.run();
    end

endmodule
