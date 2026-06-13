`timescale 1ns / 1ps

class transaction;  // transaction이므로 bit로 선언 logic 필요 없음

    rand bit [7:0] addr;
    rand bit [7:0] wdata;
    rand bit       we;
    bit      [7:0] rdata;

    constraint addr_range {addr < 10;}

    function debug_print(string name);
        $display("%t : [%s] addr = %d, wdata = %d, we = %d, rdata = %d", $time,
                 name, addr, wdata, we, rdata);
    endfunction

endclass

interface ram_interface;
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

    function new(
        mailbox#(transaction) gen2drv_mbox, event event_gen_next
    );  // 생성될 때 재정의 필요한 것
        this.gen2drv_mbox   = gen2drv_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run(int count);
        repeat (count) begin  // fork-join_any로 만드려고 repeat 씀
            tr = new();
            // assertion, ()괄호 안의 조건이 발생하지 않으면 error 띄우기
            assert (tr.randomize())
            else $error("[GEN] tr.randomize() error!");

            gen2drv_mbox.put(tr);
            tr.debug_print("GEN");
            @(event_gen_next);
        end
    endtask
endclass

class driver;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;  // 데이터 타입 transaction
    virtual ram_interface ram_vif;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual ram_interface ram_vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.ram_vif = ram_vif;
    endfunction

    task preset();
        ram_vif.addr = 0;
        ram_vif.wdata = 0;
        ram_vif.we = 0;
        @(posedge ram_vif.clk);
    endtask

    task run();
        forever begin
            //상승엣지
            gen2drv_mbox.get(tr);
            tr.debug_print("DRV");
            @(posedge ram_vif.clk);
            #1;
            ram_vif.addr = tr.addr;
            ram_vif.wdata = tr.wdata;
            ram_vif.we = tr.we;
        end
    endtask


endclass

class monitor;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;  // 데이터 타입 transaction
    virtual ram_interface ram_vif;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual ram_interface ram_vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.ram_vif = ram_vif;
    endfunction

    task run();
        forever begin
            @(posedge ram_vif.clk);
            tr = new();
            tr.addr = ram_vif.addr;
            tr.wdata = ram_vif.wdata;
            tr.we = ram_vif.we;
            tr.rdata = ram_vif.rdata;
            mon2scb_mbox.put(tr);
            tr.debug_print("MON");
        end
    endtask


endclass



class scoreboard;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;  // 데이터 타입 transaction
    event event_gen_next;  //score board에서 오는 event

    byte mem[256];  // 2상태

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
            if (tr.we) begin  // write senario
                mem[tr.addr] = tr.wdata;
            end else begin  // read senario
                if (tr.rdata == mem[tr.addr]) begin
                    pass_cnt++;
                    $display("%t : PASS", $time);
                end else begin
                    fail_cnt++;
                    $display(
                        "%t : FAIL addr = %d, rdata = %d, compare data = %d",
                        $time, tr.addr, tr.rdata, mem[tr.addr]);
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

    function new(virtual ram_interface ram_vif);
        gen2drv_mbox = new;
        mon2scb_mbox = new;
        gen          = new(gen2drv_mbox, event_gen_next);
        drv          = new(gen2drv_mbox, ram_vif);
        mon          = new(mon2scb_mbox, ram_vif);
        scb          = new(mon2scb_mbox, event_gen_next);
    endfunction

    //fork join_any 적용

    task run();

        // ram interface initial
        drv.preset();


        fork
            gen.run(20);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #10;
        $display("%t : ENV RUN TASK END", $time);


        $display("__________________________");
        $display("** SRAM IP Verification **");
        $display("** total test num = %2d **", scb.total_cnt);
        $display("** pass test num  = %2d **", scb.pass_cnt);
        $display("** fail test num  = %2d **", scb.fail_cnt);
        $display("**************************");
        $stop;
    endtask

endclass



module tb_ram_sv ();

    ram_interface ram_if ();  // 괄호 빼먹음 추가함
    environment env;

    ram_ip dut (
        .clk(ram_if.clk),
        .addr(ram_if.addr),
        .wdata(ram_if.wdata),
        .rdata(ram_if.rdata),
        .we(ram_if.we)
    );

    always #5 ram_if.clk = ~ram_if.clk;

    initial begin
        ram_if.clk = 0;
        //reset 제어는 drive에서 수행, d, q도
        env = new(ram_if);
        env.run();
    end

endmodule
