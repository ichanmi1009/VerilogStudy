`timescale 1ns / 1ps

module fifo #(

    parameter DEPTH = 4,
    BIT_WIDTH = $clog2(DEPTH) - 1
) (
    input        clk,
    input        rst,
    input  [7:0] push_data,
    input        push,
    input        pop,
    output [7:0] pop_data,
    output       full,
    output       empty
);
    wire [BIT_WIDTH:0] w_wptr, w_rptr;


    register_file #(
        .DEPTH(DEPTH)
    ) U_REG_FILE (  // 인스턴스 이름 까먹지 말기
        .clk  (clk),
        .wdata(push_data),
        .waddr(w_wptr),            // 컨트롤에서 가져올거
        .raddr(w_rptr),            // 컨트롤에서 가져올거
        .we   (((~full) & push)),
        .rdata(pop_data)
    );

    control_unit #(
        .DEPTH(DEPTH)
    ) U_CONTROL_UNIT (
        .clk  (clk),
        .rst  (rst),
        .push (push),
        .pop  (pop),
        .wptr (w_wptr),
        .rptr (w_rptr),
        .full (full),
        .empty(empty)
    );


endmodule


module register_file #(
    parameter DEPTH = 4,
    BIT_WIDTH = ($clog2(DEPTH) - 1)
) (
    input                clk,
    input  [        7:0] wdata,
    input  [BIT_WIDTH:0] waddr,
    input  [BIT_WIDTH:0] raddr,
    input                we,
    output [        7:0] rdata
);
    // define 문 추가는 숙제
    reg [7:0] register_file[0:DEPTH-1];  //[0:3] 개수

    always @(posedge clk) begin
        if (we) begin
            register_file[waddr] <= wdata;
        end
    end

    assign rdata = register_file[raddr];

endmodule

module control_unit #(
    parameter DEPTH = 4,
    BIT_WIDTH = ($clog2(DEPTH) - 1)
) (
    input                clk,
    input                rst,
    input                push,
    input                pop,
    output [BIT_WIDTH:0] wptr,
    output [BIT_WIDTH:0] rptr,
    output               full,
    output               empty
);
    reg [BIT_WIDTH:0] wptr_reg, wptr_next;
    reg [BIT_WIDTH:0] rptr_reg, rptr_next;
    reg full_reg, full_next, empty_reg, empty_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;
    // assign 없앨수도 있는데 그건 나중에

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 1'b0;
            empty_reg <= 1'b1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    always @(*) begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({
            push, pop
        })  // 외부에서 push와 pop이 들어옴.
            2'b00 : begin // 00이니까 초기상태, wptr,rptr이미 rst에서 리셋햇음. full,empty 조합으로내보내는 것보다 wptr,rptr과 같이 움직이는게 좋음
                // 이미 위에서 초기상태 끝남
            end
            2'b10: begin
                //push only
                if (!full_reg) begin  // 현재값이므로
                    wptr_next = wptr_reg + 1; // counter4와 비슷한 형태 2의 지수승으로 가게 되면 딱 떨어짐, 14개 이런게 아니라 중간에 값을 써야하면 0으로 가는걸해줘야함
                    empty_next = 1'b0;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end
            2'b01: begin
                // pop only
                if (!empty_reg) begin  // 현재 empty가 아니면
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                    if (wptr_reg == rptr_next) begin
                        empty_next = 1'b1;
                    end
                end
            end
            2'b11: begin
                // push, pop same time
                if (full_reg) begin // 우선순위 파악(full일때 push 들어오는거, empty일때 pop 나가는거, full도 아니고 empty도 아닐때 들어오는거 중에 full일때 push인게 가장 리스크가큼)
                    // pop only process
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else if (empty_reg) begin
                    //push only process
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end

    //FSM 구성(액션 : PUSH, POP이 천이 조건, 초기 : REST 상태, 내부에서 PUSH,POP이 아니라 외부에서 PUSH, POP이니까 STATE REG 안줌)

endmodule
