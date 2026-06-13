`timescale 1ns / 1ps

interface ram_intf (
    input logic clk
);
    logic       we;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;
endinterface

class transaction;
    rand logic [7:0] addr;
    rand logic [7:0] wdata;
    logic [7:0] rdata;
endclass

class tester;
    transaction tr;  // test를 하기위한 transaction 부품이 필요. 

    //rand logic [7:0] addr;
    //rand logic [7:0] data;

    virtual ram_intf ram_if;

    function new(virtual ram_intf ram_if);
        this.ram_if = ram_if; // 인스턴스 멤버인 ram_if에다가 매개변수로 들어온 ram_if를 연결한다
        tr = new();
    endfunction

    // task write_test(logic [7:0] addr, logic [7:0] data)
    task write_test();
        ram_if.we    = 1'b1;
        ram_if.addr  = tr.addr;
        ram_if.wdata = tr.wdata;
        @(posedge ram_if.clk);
        $display("we : %0h, addr : %0h, wdata : %0h", ram_if.we, ram_if.addr,
                 ram_if.wdata);
    endtask

    // task read_test(logic [7:0] addr)
    task read_test();
        ram_if.we   = 1'b0;
        ram_if.addr = tr.addr;
        @(posedge ram_if.clk);
        tr.rdata = ram_if.rdata;
        $display("we : %0h, addr : %0h, rdata : %0h", ram_if.we, ram_if.addr,
                 ram_if.rdata);
    endtask

    virtual function result();
        if (tr.wdata != tr.rdata) begin
            $display("        Fail! wdata : %0h != rdata : %0h", tr.wdata,
                     tr.rdata);
        end else begin
            $display("PASS! wdata : %0h == rdata : %0h", tr.wdata, tr.rdata);
        end
    endfunction

    virtual task test_run(int loop);
        repeat (loop) begin
            tr.randomize();
            write_test();
            read_test();
            result();
        end
    endtask

endclass

class tester_child extends tester;
    int pass, fail;

    function new(virtual ram_intf ram_if);
        super.new(ram_if);
        pass = 0;
        fail = 0;
    endfunction

    virtual function result();
        if (tr.wdata != tr.rdata) begin

            $display("        Fail! wdata : %0h != rdata : %0h", tr.wdata,

                     tr.rdata);
            fail++;

        end else begin

            $display("PASS! wdata : %0h == rdata : %0h", tr.wdata, tr.rdata);
            pass++;
        end
    endfunction

    function report();
        $display("pass count       : %0d", pass);
        $display("fail count       : %0d", fail);
        $display("total test count : %0d", pass + fail);
    endfunction

    virtual task test_run(int loop);
        repeat (loop) begin
            tr.randomize();
            write_test();
            read_test();
            result();
        end
        report();
    endtask

endclass

module tb_ram ();

    logic clk;

    ram_intf ram_if (clk);  // clk과 rst는 global signal 

    ram dut (
        .clk  (ram_if.clk),
        .we   (ram_if.we),
        .addr (ram_if.addr),
        .wdata(ram_if.wdata),
        .rdata(ram_if.rdata)
    );

    tester_child  CM; // class에 대한 handler, new 해야지 instance가 만들어짐.
    // 메모리에 할당


    always #5 clk = ~clk;  // clk 추가

    initial begin
        CM  = new(ram_if);
        clk = 0;
        repeat (5) @(posedge clk);

        // 직접 하나씩 넣어보기
        //CM.write_test(8'h00, 8'h01);
        //CM.read_test(8'h00);
        //CM.write_test(8'h01, 8'h02);
        //CM.read_test(8'h01);
        //CM.write_test(8'h02, 8'h03);
        //CM.read_test(8'h02);
        //CM.write_test(8'h03, 8'h04);
        //CM.read_test(8'h03);

        // 랜덤 값 생성
        //repeat (100) begin
        //    CM.randomize();
        //    CM.write_test();
        //    CM.read_test();
        //end

        // 수업 시간 중 내가 한 것
        //for (i = 0; i < 256; i++) begin
        //    CM.write_test(i, i);
        //end
        //for (i = 0; i < 256; i++) begin
        //    CM.read_test(i);
        //end

        // 좀 더 객체 지향적으로 cm에게 시키게(위에는 iu가 직접 하는게 아니라 시키는 개념(뭐 해라 뭐 해라))
        // 이번에는 직접 cm에게 task 해 하면 알아서 할수있게
        CM.test_run(1000);

        repeat (5) @(posedge clk);
        $finish;

    end


endmodule
