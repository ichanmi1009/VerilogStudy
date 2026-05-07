`timescale 1ns / 1ps

module watch_fnd_adapter (
    input [4:0] i_hour,
    input [2:0] i_min_d10,
    input [3:0] i_min_d1,
    input [2:0] i_sec_d10,
    input [3:0] i_sec_d1,
    input [6:0] i_msec,

    output [4:0] hour,
    output [5:0] min,
    output [5:0] sec,
    output [6:0] msec
);


    assign hour = i_hour;
    assign min  = i_min_d10 * 4'd10 + i_min_d1;
    assign sec  = i_sec_d10 * 4'd10 + i_sec_d1;
    assign msec = i_msec;

endmodule
