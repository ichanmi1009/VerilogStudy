`timescale 1ns / 1ps

class transction;
    //genertor은 외부 인터페이스랑 연결해야할게 필요했으나, transction에서는 new 선언 생략 가능
    rand bit [7:0] a;  // 2상태 bit(0,1), 
    //랜덤으로 만들어질 것임을 지정 rand
    rand bit [7:0] b;
    rand bit       mode;  // 0:sum, 1:sub
    bit      [7:0] s;
    bit            c;
endclass

// 사용자 타입의 자료형
interface adder_interface ();
    // 멤버 변수
    logic [7:0] a;
    logic [7:0] b;
    logic       mode;  // 0:sum, 1:sub
    logic [7:0] s;
    logic       c;
endinterface


// 상속 x, 생성, instance화, 메모리에 할당
class generator;
    transction tr;
    virtual adder_interface adder_vif; // sw에 adder_interface 만듬? 왜 virtual일까
    // generator 객체인데, 하드웨어를 연결하다 보니까 실질적으로 interface라는 이름이 있는데. 이는 전달해주는 역할이라서?
    // 이를 new 생성자로 연결. 중간 이름 개념 내부에 있는거랑 외부에서 들어오는거랑 연결 실제로는 tb_alu에서 해야하는데
    // 일단 설계를 해야해서 new funtion이 불릴때 adder_vif = adder_vinterf

    function new(virtual adder_interface adder_vinterf);
        // c++에서 new의 의미? 공부
        adder_vif = adder_vinterf;
        tr = new;
    endfunction

    // rand 키워드가 붙어있는 변수를 랜덤화해라. randomize(sv에서 제공되는 함수)
    task run(int repeat_count);
        // tr = new; 여기로 해도 되는데. 단점 : cpu에 load가 걸림. 리소스 관리에는 좋은데
        repeat (repeat_count) begin
            tr.randomize();
            adder_vif.a = tr.a;
            adder_vif.b = tr.b;
            adder_vif.mode = tr.mode;
            // s,c 는 drive 대상이 아니므로 연결하지 않음
            // 시간보내는 역할은 drive가 해야함
            #10;
        end
    endtask

endclass

module tb_alu ();

    adder_interface adder_if ();
    generator gen; // generator class에 gen 만듬. gen에다가 tr을 가져다 쓸 수 있을까?
    // interface와 generator이 연결 x. U 키워드와 인터페이스 키워드. gen에다가 interface 연결

    adder dut (
        // adder_if.a 에서 .a는 멤버 연결자
        .a   (adder_if.a),
        .b   (adder_if.b),
        .mode(adder_if.mode),  // 0:sum, 1:sub
        .s   (adder_if.s),
        .c   (adder_if.c)
    );

    initial begin
        gen = new(adder_if);  // new라는 funtion을 부름으로써
        gen.run(10);  // 10 넣으면 10번 반복
        //adderdut 인스턴스 하고 initioal begin end 어떻게 실행? 순서대로 실행
        //랜더마이즈하고 인터페이스 값 할당하고 10ns 보내고. 제너레이트 run 끝나고 나오면 stop
        $stop;
    end

endmodule

// 실체 : 메모리 할당
// task와 funtion 차이 : 시간을 제어할 수 있는가 없는가
// 시스템 베릴로그 void funtion도 지원
