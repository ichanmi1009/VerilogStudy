`timescale 1ns / 1ps

class transaction;
    // genertor은 외부 인터페이스랑 연결해야 할게 필요했으나, transaction에서는 new 선언 생략 가능
    // new function이 필요 없어서 안 만든거. 객체 생성할때 동적할당해야해서 new()를 해야해서/ new()는 동적할당으로 생성하겠다./ tr은 객체를 생성하기 위한 핸들러 역할 ex)3개 만들고 싶으면 tr1, tr2, tr3등
    // 재정의 new를 생성할 때마다 재정의하는거, basic만 현재 설계중
    rand bit [7:0] a;  // 2상태 bit(0,1), 
    //랜덤으로 만들어질 것임을 지정 rand
    rand bit [7:0] b;
    rand bit       mode;  // 0:sum, 1:sub
    bit      [7:0] s;
    bit            c;

    // task로도 가능
    function debug_print(string name);
        $display("%t : [%s] a = %d, b = %d, mode = %d, s = %d, c = %d", $time,
                 name, a, b, mode, $signed(s),
                 c);  // s값 편하게 보기위해 $signed 붙임
    endfunction

    //constraint in_range { // 1번 경우
    //    a > 128;
    //    b > 250;
    //}

    //constraint in_range {a inside {[0 : 127]};} // 2번 경우 

    //constraint mode_distribute { // 3번 경우 확률
    //    mode dist {
    //        0 :/ 90,
    //        1 :/ 10
    //    };
    //}

    constraint in_range {a inside {[0 : 127]};}

    constraint in_b {
        if (mode == 0)
        b inside {0, 1, 2, 3, 15, 31, 250};
        else
        b > 128;
    }

    constraint mode_distribute {
        mode dist {
            0 :/ 80,
            1 :/ 20
        };
    }

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

// generator : random 값 생성
// to generator random stimulus
class generator;

    transaction tr;  // 공간 만들어둔거
    mailbox #(transaction) gen2drv_mbox; // mailbox , transaction 이름의 클래스 객체만 담겠다, 이름
    event event_gen_next;

    function new(mailbox#(transaction) gen2drv_mbox, event event_gen_next);
        // transaction - datatype
        this.gen2drv_mbox = gen2drv_mbox; // 내부에 있는 것과 연결해라. 
        this.event_gen_next = event_gen_next; // gen이 생성될 때 한번만 알려주면 될듯
        // tr = new(); 여기에 할당하면 generator 생성될때만 transaction tr 한번만 만들어짐. 생성해서 패킹해서 풋하도록 바꿔야함. tran생성위치 이동필요
        // tr 랜더마이즈해서 쓸려면 생성해서 패킹해서 주고.를 반복해야함. task로 가져오면 task생성패킹주고 과정 반복
        // tr 랜더마이즈해서 쓸려면 생성해서 패킹해서 주고.를 반복해야함. task로 가져오면 task생성패킹주고 과정 반복
    endfunction

    task run(int count);
        repeat (count) begin
            tr = new();
            // repeat (count) begin
            // 동적생성, randomize, mailbox, gen2drv.put
            // run이 불릴때마다 생성해서 랜더마이징해서 put 반복가능
            tr.randomize();  // drive가 받아야할 값
            tr.debug_print("GEN");
            gen2drv_mbox.put(tr);
            @(event_gen_next); // @ - event가 들어올 때까지 wait 하고 있는 상황
        end
        $display("GEN end task");
    endtask

endclass

// driver : 제너레이터에서 tr을 만들고 데이터를 쓰고 저장. driver는 가져다가 쓰기만 하는 역할
// mail box라는 인터프로세스, ipc interprocessor, 객체와 객체를 전달해줄 통로 역할을 할 우편 배달원이 필요.
// to drive by interface stimulus
class driver;

    transaction tr;
    virtual adder_interface adder_vif;
    mailbox #(transaction) gen2drv_mbox;
    event event_gen_next;
    function new(mailbox#(transaction) gen2drv_mbox, event event_gen_next,
                 virtual adder_interface adder_vinterf);

        this.adder_vif = adder_vinterf; // 부모에서 가져온게 아니라 내꺼에서 가져온거다 this. 안써도 상관이 없었긴했음
        this.event_gen_next = event_gen_next;
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction  ///new()

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            // wait : tr 가져올때까지 기다리는 동작 시킬예정
            // 받는거라서 get, tr 생성은. 동적 할당 누가 햇어? 제너레이터에서 해서 mbox에 넣어준거를 가져온거고. 그 가져온핸들러이름이 tr인데 앞에 tr이랑 다른 tr임. 걍 우편배달원 이름이 같은거라고 생각
            tr.debug_print("DRV");
            adder_vif.a    = tr.a;
            adder_vif.b    = tr.b;
            adder_vif.mode = tr.mode;
            // event 위치 -> 생성해서 드라이브하고 바로 하자마자 다시 생성할꺼니까 #10 뒤에 동작하는게 나을듯
            #10;
            ->event_gen_next;
        end
        $display("DRV task end");
    endtask

endclass

class monitor;

    transaction tr;
    virtual adder_interface adder_vif;
    mailbox #(transaction) mon2scb_mbox;
    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual adder_interface adder_vinterf);
        this.mon2scb_mbox = mon2scb_mbox;
        this.adder_vif = adder_vinterf;
    endfunction

    //task가 불리면 패킹해서 tr로 보내는데 언제? 결과에 대한 타이밍을 보려면 10n를 보면 됌
    task run();
        forever begin
            #5;
            tr = new();
            tr.a = adder_vif.a;
            tr.b = adder_vif.b;
            tr.mode = adder_vif.mode;
            tr.s = adder_vif.s;
            tr.c = adder_vif.c;
            mon2scb_mbox.put(tr);
            tr.debug_print("MON");
            #5;
        end
    endtask

endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;
    function new(mailbox#(transaction) mon2scb_mbox);
        this.mon2scb_mbox = mon2scb_mbox;
    endfunction

    task run();
        // 미리 연산
        bit [7:0] expected_sum;
        bit expected_carry;

        forever begin
            mon2scb_mbox.get(tr);
            tr.debug_print("SCB");
            // pass / fail decision
            total_cnt++;
            // 입력 , 출력 값 다 존재(모니터링에서)
            // 이 입력값을 가지고 소프트웨어에서 연산된 결과를 비교해도 되고
            // 오차가 있으면 오차가 얼마? 오차를 표현해주면 좋음 잘못된 것을 예측 가능

            //to calculate expected data
            if (tr.mode) begin
                {expected_carry, expected_sum} = tr.a - tr.b;
            end else begin
                {expected_carry, expected_sum} = tr.a + tr.b;
            end
            // to compare between expexted data and monitor data(result)
            if ((tr.s == expected_sum) && (tr.c == expected_carry)) begin
                $display("%t, [pass] !!", $time);
                pass_cnt++;
            end else begin
                $display("%t, [fail] !! a = %d, b = %d, sum = %d, carry = %d",
                         $time, tr.mode, tr.a, tr.b, tr.s, tr.c);
                fail_cnt++;
            end
        end
    endtask
endclass

// manager
class environment;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;
    // gen과 drive 사이 연결
    // virtual adder_interface adder_vif;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    // event 통로 만들어주기 (0508)
    event                  event_gen_next;

    function new(virtual adder_interface adder_vif);
        gen2drv_mbox = new;
        mon2scb_mbox = new;
        gen = new(gen2drv_mbox, event_gen_next);
        drv = new(gen2drv_mbox, event_gen_next, adder_vif);
        mon = new(mon2scb_mbox, adder_vif);
        scb = new(mon2scb_mbox);
    endfunction

    // fork-join
    task run(int count);
        fork
            gen.run(20);
            drv.run();
            mon.run();
            scb.run();
        join_any
        $display("ENV fork join_any end");
        $display("-------------------------");
        $display("** Adder Verification **");
        $display("** total_test = %5d **", scb.total_cnt);  // %d %5d 차이
        $display("** pass_count = %5d **", scb.pass_cnt);
        $display("** fail_count = %5d **", scb.fail_cnt);
        $display("-------------------------");
    endtask

    // begin-end
    //task run(int count);
    //    repeat (count) begin
    //        gen.run();
    //        drv.run();
    //        mon.run();
    //        scb.run();
    //        // 모니터링 하는 시점이 10n? 젠run, drive run안에서 10n 만큼 delay 줬는데 10n에서 모니터링하면 문제 발생하려나?
    //        // 시뮬레이터는 시간을 drive 하지 않으면 값이 안바뀜
    //        // time slot 상 blocking 연산 먼저하고.? 상관없음. 해도 결과에 영향을 미치지 않으면
    //    end
    //endtask

endclass

//rand는 랜더마이즈만을 위해서 쓰는게 아님. 랜더마이즈 할때는 rand가 붙어잇는 변수를 랜더마이즈 하고 아니면 일반변수로 간주됌

module tb_alu_sv ();

    adder_interface adder_if ();
    environment env; // generator class에 gen 만듬. gen에다가 tr을 가져다 쓸 수 있을까?
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
        env = new(adder_if);
        env.run(10);
        $stop;
    end
endmodule
