`timescale 1ns / 1ps
module ex(
    input a,
    input b,
    input c,
    input d,
    output y0,
    output y1
);

    assign y0 = ~((b & c) & d);
    assign y1 = ~(~(a | b)^(b & c));

endmodule
