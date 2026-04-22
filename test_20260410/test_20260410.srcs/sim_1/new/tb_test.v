`timescale 1ns / 1ps

module tb_test ();

    integer intA, intB, intC, intD;
    reg [3:0] d, f;
    reg result;

    initial begin
        intA = -12 / 4;
        intB = -'d12 / 4;
        intC = -'sd12 / 4;
        intD = -(4'sd12) / 4;

        $display("%d, %d, %d, %d", intA, intB, intC, intD);

        d = 4'b1001;
        f = 4'b1xxz;
        if (d == f) d = 1;
        else d = 0;
        $display("%b", d);
        $stop;
    end


endmodule
