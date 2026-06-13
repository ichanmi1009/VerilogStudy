`timescale 1ns / 1ps

interface alu_intf;
    logic       opcode;
    logic [7:0] A;
    logic [7:0] B;
    logic [7:0] result;
endinterface  

class tester;
    virtual alu_intf alu_if;

    function new(virtual alu_intf alu_if);
        this.alu_if = alu_if; // this 내 멤버. 오른쪽 매개변수로 들어온 인터페이스를 연결하는 의미
        // 링크를 가져오는 개념이라 virtual이라고 적음
    endfunction  //new()

    task add_test(logic [7:0] add_a, logic [7:0] add_b);
        alu_if.opcode = 1'b0;
        alu_if.A = add_a;
        alu_if.B = add_b;
    endtask

    task sub_test(logic [7:0] sub_a, logic [7:0] sub_b);
        alu_if.opcode = 1'b1;
        alu_if.A = sub_a;
        alu_if.B = sub_b;
    endtask
endclass

module tb_ALU ();
    alu_intf alu_if ();  // 이게 물리적인 interface wire

    ALU dut (
        .opcode(alu_if.opcode),
        .A(alu_if.A),
        .B(alu_if.B),
        .result(alu_if.result)
    );

    tester BTS;
    tester BlackPink;
    tester test1;
    tester test2;

    initial begin
        alu_if.opcode = 0;
        alu_if.A = 0;
        alu_if.B = 0;
        #10;
        BTS = new(alu_if);  // make instance, 이걸 써야지 메모리에 올라감, BTS라고 하는 Tester 객체 생성
        BlackPink = new(alu_if);
        #10;
        BTS.add_test(10, 20);  // BTS가 ADD TEST를 함
        #10;
        BTS.sub_test(10, 5);
        #10;
        BlackPink.add_test(4, 6);
        #10;
        BlackPink.sub_test(6, 4);
        #10;
        $finish;
    end

endmodule
