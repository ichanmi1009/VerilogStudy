`timescale 1ns / 1ps

module adder_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] s,
    output led
);
    wire w_c0;

    full_adder_4bit U_FA_0 (
        .a  (a[3:0]),
        .b  (b[3:0]),
        .cin(1'b0),
        .s  (s),
        .c  (w_c0)
    );

    full_adder_4bit U_FA_1 (
        .a  (a[7:4]),
        .b  (b[7:4]),
        .cin(w_c0),
        .s  (s),
        .c  (led)
    );

endmodule





module full_adder_4bit (
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] s,
    output c
);
    wire w_c0, w_c1, w_c2, w_c3;

    full_adder U_FA0 (
        .a  (a[0]),
        .b  (b[0]),
        .cin(cin),
        .s  (s[0]),
        .c  (w_c0)   // to FA1 of cin
    );
    full_adder U_FA1 (
        .a  (a[1]),
        .b  (b[1]),
        .cin(w_c0),
        .s  (s[1]),
        .c  (w_c1)   // to FA2 of cin
    );
    full_adder U_FA2 (
        .a  (a[2]),
        .b  (b[2]),
        .cin(w_c1),
        .s  (s[2]),
        .c  (w_c2)   // to FA3 of cin
    );
    full_adder U_FA3 (
        .a  (a[3]),
        .b  (b[3]),
        .cin(w_c2),
        .s  (s[3]),
        .c  (c)
    );
endmodule


module full_adder (
    input  a,
    input  b,
    input  cin,
    output s,
    output c
);

    wire w_s1, w_c1, w_c2;  // vaule not change, just connected 

    assign c = w_c1 | w_c2;

    half_adder U_HA0 (
        .a(a),     // .a half adder port a, (a) from full_adder input a
        .b(b),     // from full_adder input b
        .s(w_s1),
        .c(w_c1)
    );

    half_adder U_HA1 (
        .a(w_s1),  // .a half adder port a, (a) from full_adder input a
        .b(cin),   // from full_adder input cin
        .s(s),     // to full_adder output s
        .c(w_c2)
    );

endmodule

module half_adder (
    input  a,
    input  b,
    output s,
    output c
);

    assign s = a ^ b;
    assign c = a & b;

endmodule
