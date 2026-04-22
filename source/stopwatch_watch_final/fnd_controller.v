`timescale 1ns / 1ps

module fnd_controller #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input                    clk,
    input                    rst,
    input  [3:0]             sw,     
    input  [MSEC_WIDTH -1:0] msec,
    input  [ SEC_WIDTH -1:0] sec,
    input  [ MIN_WIDTH -1:0] min,
    input  [HOUR_WIDTH -1:0] hour,
    output [            3:0] fnd_com,
    output [            7:0] fnd_data,


    input                   i_left,
    input                   i_right
);

    wire [3:0] w_out_mux, w_out_mux_msec_sec, w_out_mux_min_hour;
    wire [3:0] w_msec_digit_1, w_msec_digit_10;
    wire [3:0] w_sec_digit_1, w_sec_digit_10;
    wire [3:0] w_min_digit_1, w_min_digit_10;
    wire [3:0] w_hour_digit_1, w_hour_digit_10;
    wire [2:0] w_digit_sel;
    wire w_1khz;
    wire w_dot_onoff;
    wire [1:0] w_cursor_pos;

    wire [3:0] w_blink_1, w_blink_10, w_blink_100, w_blink_1000;


    digit_splitter #(
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_MSEC_DS (
        .digit_in(msec),
        .digit_1 (w_msec_digit_1),
        .digit_10(w_msec_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(SEC_WIDTH)
    ) U_SEC_DS (
        .digit_in(sec),
        .digit_1 (w_sec_digit_1),
        .digit_10(w_sec_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(MIN_WIDTH)
    ) U_MIN_DS (
        .digit_in(min),
        .digit_1 (w_min_digit_1),
        .digit_10(w_min_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_HOUR_DS (
        .digit_in(hour),
        .digit_1 (w_hour_digit_1),
        .digit_10(w_hour_digit_10)
    );

    comparator U_COMP_DOTNONFF (
        .comp_in  (msec),
        .dot_onoff(w_dot_onoff)
    );

    mux_8x1 U_MUX_MSEC_SEC (
        .in0(w_blink_1),  // digit 1
        .in1(w_blink_10),  // digit 10
        .in2(w_blink_100),  // digit 1
        .in3(w_blink_1000),
        .in4(4'hf),
        .in5(4'hf),
        .in6({3'b111, w_dot_onoff}),  // dpt display
        .in7(4'hf),
        .sel(w_digit_sel),  // to select input
        .out_mux(w_out_mux_msec_sec)
    );

    mux_8x1 U_MUX_MIN_HOUR (
        .in0(w_blink_1),  // digit 1
        .in1(w_blink_10),  // digit 10
        .in2(w_blink_100),  // digit 1
        .in3(w_blink_1000),  // digit 10
        .in4(4'hf),
        .in5(4'hf),
        .in6({3'b111, w_dot_onoff}),  // dot display
        .in7(4'hf),
        .sel(w_digit_sel),  // to select input
        .out_mux(w_out_mux_min_hour)
    );


    mux_2x1 U_MUX_2x1 (
        .in0(w_out_mux_msec_sec),
        .in1(w_out_mux_min_hour),
        .sel(sw[0]),
        .out_mux(w_out_mux)
    );

    bcd U_BCD (
        .bin(w_out_mux),
        .bcd_data(fnd_data)
    );


    clk_div_1khz U_CLK_DIV_1KHZ (
        .clk(clk),
        .rst(rst),
        .o_1khz(w_1khz)
    );

    counter_8 U_COUNTER_8 (
        .clk(w_1khz),
        .rst(rst),
        .digit_sel(w_digit_sel)
    );


    decoder_2x4 U_DECODER_2x4 (
        .decoder_in(w_digit_sel[1:0]),  // 2비트만 가져와야해서
        .fnd_com(fnd_com)
    );

    cursor_ctrl U_CURSOR_CTRL (
        .clk(clk),
        .rst(rst),
        .btn_left(i_left),
        .btn_right(i_right),
        .o_cursor_pos(w_cursor_pos) // 0~1 값 출력
    );

    digit_blink_mux U_BLINK_MUX(
    .sw(sw),
    .i_msec_digit_1(w_msec_digit_1), 
    .i_msec_digit_10(w_msec_digit_10),
    .i_sec_digit_1(w_sec_digit_1), 
    .i_sec_digit_10(w_sec_digit_10),
    .i_min_digit_1(w_min_digit_1), 
    .i_min_digit_10(w_min_digit_10),
    .i_hour_digit_1(w_hour_digit_1), 
    .i_hour_digit_10(w_hour_digit_10), 
    .i_cursor_pos(w_cursor_pos),
    .i_blink_sig(w_dot_onoff), 
    .o_blink_1(w_blink_1),    
    .o_blink_10(w_blink_10),   
    .o_blink_100(w_blink_100),      
    .o_blink_1000(w_blink_1000)      
    );


endmodule

module comparator (
    input  [6:0] comp_in,
    output       dot_onoff
);
    // 0 ~ 49 ; false 0, 50 ~ 99 : true 1
    assign dot_onoff = (comp_in > 49) ? 1 : 0;
endmodule

module mux_2x1 (
    input [3:0] in0,
    input [3:0] in1,
    input sel,
    output [3:0] out_mux
);

    assign out_mux = (sel) ? in1 : in0;  // in0 : msec_sec, in1 : min_hour 

endmodule


module clk_div_1khz (
    input  clk,
    input  rst,
    output o_1khz
);

    reg [15:0] counter_reg;
    reg o_1khz_reg;

    assign o_1khz = o_1khz_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 16'd0;
            o_1khz_reg   <= 1'b0; // o_1khz 초기화해줌 바로 reg 형태로 바꾸는 것이 아니라
        end else begin
            counter_reg <= counter_reg + 1;  //6만 오천 오백까지 증가
            if (counter_reg == 50000 - 1) begin  //50000-1
                counter_reg <= 16'd0;
                o_1khz_reg  <= ~o_1khz_reg;
            end
        end
    end

endmodule

module counter_8 (  // counter_4에서 8로 수정
    input clk,
    input rst,
    output [2:0] digit_sel  // output 3비트로 수정
);
    reg [2:0] counter_reg;  // 내부 3비트도 수정

    assign digit_sel = counter_reg;  // 4가지 경우

    always @(posedge clk, posedge rst) begin //clk 신호의 상승엣지가 발생할때마다 begin end 구현해라
        if (rst) begin
            counter_reg <= 0;  // 0 초기화 <= 0
        end else begin
            counter_reg <= counter_reg + 1;
        end
    end

endmodule



module decoder_2x4 (
    input [1:0] decoder_in,
    output reg [3:0] fnd_com
);

    always @(*) begin
        case (decoder_in)
            2'b00:   fnd_com = 4'b1110;
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end


endmodule


module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH-1:0] digit_in,
    output [          3:0] digit_1,
    output [          3:0] digit_10
);

    assign digit_1  = digit_in % 10;  // digit 100
    assign digit_10 = (digit_in / 10) % 10;  // digit 1000

endmodule

module mux_8x1 (  // mux 8x1로 설정
    input [3:0] in0,  // digit 1
    input [3:0] in1,  // digit 10
    input [3:0] in2,  // digit 100
    input [3:0] in3,  // digit 1000
    input [3:0] in4,  // 도트 f
    input [3:0] in5,  // 도트 f
    input [3:0] in6,  // 도트 e, f
    input [3:0] in7,  // 도트 f
    input [2:0] sel,  // to select input
    output [3:0] out_mux
);
    reg [3:0] out_reg;
    assign out_mux = out_reg;

    // mux, (*) all input : sensitivity list
    always @(*) begin
        case (sel)
            3'b000:  out_reg = in0;
            3'b001:  out_reg = in1;
            3'b010:  out_reg = in2;
            3'b011:  out_reg = in3;
            3'b100:  out_reg = in4;
            3'b101:  out_reg = in5;
            3'b110:  out_reg = in6;
            3'b111:  out_reg = in7;
            default: out_reg = 4'b0000;
        endcase
    end

endmodule


module bcd (
    input [3:0] bin,
    output reg [7:0] bcd_data
);

    always @(bin) begin
        case (bin)
            4'b0000: bcd_data = 8'hC0;
            4'b0001: bcd_data = 8'hF9;
            4'b0010: bcd_data = 8'hA4;
            4'b0011: bcd_data = 8'hB0;
            4'b0100: bcd_data = 8'h99;
            4'b0101: bcd_data = 8'h92;
            4'b0110: bcd_data = 8'h82;
            4'b0111: bcd_data = 8'hF8;
            4'b1000: bcd_data = 8'h80;
            4'b1001: bcd_data = 8'h90;
            4'b1010: bcd_data = 8'h88;
            4'b1011: bcd_data = 8'h83;
            4'b1100: bcd_data = 8'hC6;
            4'b1101: bcd_data = 8'hA1;
            4'b1110: bcd_data = 8'h7F;  // 도트 켜진 상태(E), dot on
            4'b1111: bcd_data = 8'hFF;  // 도트 꺼진 상태(F), all off
            default: bcd_data = 8'hFF;
        endcase
    end

endmodule


module cursor_ctrl (
    input  wire       clk,
    input  wire       rst,
    input  wire       btn_left,
    input  wire       btn_right,
    output wire [1:0] o_cursor_pos
);

    // 1. 최소한의 엣지 검출 (버튼을 꾹 눌러도 딱 1칸만 움직이게 함)
    reg L_d1, L_d2;
    reg R_d1, R_d2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            L_d1 <= 0; L_d2 <= 0;
            R_d1 <= 0; R_d2 <= 0;
        end else begin
            L_d1 <= btn_left;  L_d2 <= L_d1;
            R_d1 <= btn_right; R_d2 <= R_d1;
        end
    end

    wire w_left_edge  = L_d1 & ~L_d2;
    wire w_right_edge = R_d1 & ~R_d2;

    // 2. 커서 위치 
    reg [1:0] cursor_pos;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cursor_pos <= 2'd0; // 리셋 시 맨 오른쪽(0번) 자리로 초기화
        end else begin
            if (w_left_edge)       cursor_pos <= 2'd2;
            else if (w_right_edge) cursor_pos <= 2'd1;
        end
    end

    assign o_cursor_pos = cursor_pos;

endmodule

module digit_blink_mux (
    input  [3:0] sw,
    //원본숫자
    input  [3:0] i_msec_digit_1, 
    input  [3:0] i_msec_digit_10,
    input  [3:0] i_sec_digit_1, 
    input  [3:0] i_sec_digit_10,
    input  [3:0] i_min_digit_1, 
    input  [3:0] i_min_digit_10,
    input  [3:0] i_hour_digit_1, 
    input  [3:0] i_hour_digit_10,
    input  [1:0] i_cursor_pos, // 현재 커서 위치 (0~2)
    input        i_blink_sig,  // 깜빡임 펄스 (0 또는 1)
    output reg [3:0] o_blink_1,    // 깜빡임이 적용된 출력 (1의 자리)
    output reg [3:0] o_blink_10,   // 깜빡임이 적용된 출력 (10의 자리)
    output reg [3:0] o_blink_100,      // 깜빡임이 적용된 출력 (100의 자리)
    output reg [3:0] o_blink_1000      // 깜빡임이 적용된 출력 (1000의 자리)
);

    // "커서가 내 자리에 있고 && 깜빡임 신호가 0일 때" -> 꺼짐 선택
    // "그 외의 모든 경우" -> 원본 숫자 선택
    // sw == 0 : msec_sec, sw == 1 : min_hour 
    always @(*) begin
        if(sw[1] == 1 && i_cursor_pos != 2'd0) begin
            if(sw[0] == 1) begin
                // 커서가 1이면 분(min) 두 자리가 깜빡임
                o_blink_1  = (i_cursor_pos == 2'd1 && i_blink_sig == 0) ? 4'hf : i_min_digit_1;
                o_blink_10 = (i_cursor_pos == 2'd1 && i_blink_sig == 0) ? 4'hf : i_min_digit_10;
                // 커서가 2이면 시(hour) 두 자리가 깜빡임
                o_blink_100  = (i_cursor_pos == 2'd2 && i_blink_sig == 0) ? 4'hf : i_hour_digit_1;
                o_blink_1000 = (i_cursor_pos == 2'd2 && i_blink_sig == 0) ? 4'hf : i_hour_digit_10;
                
            end
            else begin
                // 커서가 1이면 밀리초(msec) 두 자리가 깜빡임
                o_blink_1  = (i_cursor_pos == 2'd1 && i_blink_sig == 0) ? 4'hf : i_msec_digit_1;
                o_blink_10 = (i_cursor_pos == 2'd1 && i_blink_sig == 0) ? 4'hf : i_msec_digit_10;
                // 커서가 2이면 초(sec) 두 자리가 깜빡임
                o_blink_100  = (i_cursor_pos == 2'd2 && i_blink_sig == 0) ? 4'hf : i_sec_digit_1;
                o_blink_1000 = (i_cursor_pos == 2'd2 && i_blink_sig == 0) ? 4'hf : i_sec_digit_10;
            end
        end else begin 
            // 기본 (깜빡임 없이 원본 숫자만 출력)
            if(sw[0] == 1) begin
                o_blink_1    = i_min_digit_1;
                o_blink_10   = i_min_digit_10;
                o_blink_100  = i_hour_digit_1;
                o_blink_1000 = i_hour_digit_10;
            end
            else begin
                o_blink_1    = i_msec_digit_1;
                o_blink_10   = i_msec_digit_10;
                o_blink_100  = i_sec_digit_1;
                o_blink_1000 = i_sec_digit_10;
            end
        end
    end


endmodule
