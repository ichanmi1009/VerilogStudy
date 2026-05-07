`timescale 1ns / 1ps

module digit #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5,
    UT_WIDTH = 9,
    DH_WIDTH = 8
) (
    input  [MSEC_WIDTH - 1:0] msec,
    input  [ SEC_WIDTH - 1:0] sec,
    input  [ MIN_WIDTH - 1:0] min,
    input  [HOUR_WIDTH - 1:0] hour,
    input  [   UT_WIDTH -1:0] ut,
    input  [   DH_WIDTH -1:0] hm,
    input  [   DH_WIDTH -1:0] tm,
    output [             7:0] msec_digit,
    output [             7:0] sec_digit,
    output [             7:0] min_digit,
    output [             7:0] hour_digit,
    output [            15:0] ut_digit,
    output [             7:0] hm_digit,
    output [             7:0] tm_digit
);

    wire [3:0] msec_digit_1, msec_digit_10;
    wire [3:0] sec_digit_1, sec_digit_10;
    wire [3:0] min_digit_1, min_digit_10;
    wire [3:0] hour_digit_1, hour_digit_10;
    wire [3:0] ut_digit_1, ut_digit_10, ut_digit_100, ut_digit_1000;
    wire [3:0] tm_digit_1, tm_digit_10, hm_digit_1, hm_digit_10;

    assign msec_digit = {msec_digit_10, msec_digit_1};
    assign sec_digit  = {sec_digit_10, sec_digit_1};
    assign min_digit  = {min_digit_10, min_digit_1};
    assign hour_digit = {hour_digit_10, hour_digit_1};
    assign ut_digit   = {ut_digit_1000, ut_digit_100, ut_digit_10, ut_digit_1};
    assign tm_digit   = {tm_digit_10, tm_digit_1};
    assign hm_digit   = {hm_digit_10, hm_digit_1};

    digit_splitter #(
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_MSEC_DS (
        .digit_in(msec),
        .digit_1(msec_digit_1),
        .digit_10(msec_digit_10),
        .digit_100(),
        .digit_1000()
    );

    digit_splitter #(
        .BIT_WIDTH(SEC_WIDTH)
    ) U_SEC_DS (
        .digit_in(sec),
        .digit_1(sec_digit_1),
        .digit_10(sec_digit_10),
        .digit_100(),
        .digit_1000()
    );

    //min DS
    digit_splitter #(
        .BIT_WIDTH(MIN_WIDTH)
    ) U_MIN_DS (
        .digit_in(min),
        .digit_1(min_digit_1),
        .digit_10(min_digit_10),
        .digit_100(),
        .digit_1000()
    );

    //min DS
    digit_splitter #(
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_HOUR_DS (
        .digit_in(hour),
        .digit_1(hour_digit_1),
        .digit_10(hour_digit_10),
        .digit_100(),
        .digit_1000()
    );

    digit_splitter #(
        .BIT_WIDTH(UT_WIDTH)
    ) U_UT_DS (
        .digit_in(ut),
        .digit_1(ut_digit_1),
        .digit_10(ut_digit_10),
        .digit_100(ut_digit_100),
        .digit_1000(ut_digit_1000)
    );

    digit_splitter #(
        .BIT_WIDTH(DH_WIDTH)
    ) U_DH_HM_DS (
        .digit_in(hm),
        .digit_1(hm_digit_1),
        .digit_10(hm_digit_10),
        .digit_100(),
        .digit_1000()
    );

    digit_splitter #(
        .BIT_WIDTH(DH_WIDTH)
    ) U_DH_TM_DS (
        .digit_in(tm),
        .digit_1(tm_digit_1),
        .digit_10(tm_digit_10),
        .digit_100(),
        .digit_1000()
    );

endmodule

module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH - 1:0] digit_in,   //14bit
    output [            3:0] digit_1,
    output [            3:0] digit_10,
    output [            3:0] digit_100,
    output [            3:0] digit_1000
);

    assign digit_1 = digit_in % 10;  //digit 1
    assign digit_10 = (digit_in / 10) % 10;  //digit 10
    assign digit_100 = (digit_in / 100) % 10;  //digit 100
    assign digit_1000 = (digit_in / 1000) % 10;  //digit 1000

endmodule
