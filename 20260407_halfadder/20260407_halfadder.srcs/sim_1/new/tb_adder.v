`timescale 1ns / 1ps

module tb_full_adder_4bit();

    reg a0, a1, a2, a3, b0, b1, b2, b3, cin;
    wire s0, s1, s2, s3, c;
    // instanciation
    // dut : design under test
    // uut : unit under test

    full_adder_4bit dut (
    .a0(a0),
    .b0(b0),
    .a1(a1),
    .b1(b1),
    .a2(a2),
    .b2(b2),
    .a3(a3),
    .b3(b3),
    .cin(cin),
    .s0(s0),
    .s1(s1),
    .s2(s2),
    .s3(s3),
    .c(c)
    );

    initial begin
        // init, time control

        a0 = 0,
        b0 = 0,
        a1 = 0,
        b1 = 0,
        a2 = 0,
        b2 = 0,
        a3 = 0,
        b3 = 0,
        cin = 0,
        #10;
        a0 = 0;
        a1 = 0;
        a2 = 0;
        a3 = 0;
        b0 = 0;
        b1 = 0;
        b2 = 0;
        b3 = 0;
        cin = 0;
        #10;
        a = 1;
        b = 0;
        cin = 0;
        #10;
        a = 1;
        b = 1;
        cin = 0;
        #10;
        a = 0;
        b = 0;
        cin = 1;
        #10;
        a = 0;
        b = 1;
        cin = 1;
        #10;
        a = 1;
        b = 0;
        cin = 1;
        #10;
        a = 1;
        b = 1;
        cin = 1;
        #10;
        $stop;
    end



endmodule
