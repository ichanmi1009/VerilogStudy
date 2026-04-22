`timescale 1ns / 1ps

module tb_test1 ();

    reg a, b;
    wire y;

    initial begin
        // blocking
        a = 0;
        b = 1;
        b = a;
        a = b;
        $display("bloking : a = %d, b = %d", a, b);

        // non blocking(NB) Same timeslot 
        a = 0;
        b = 1;
        #1;
        b <= a;
        a <= b;
        #1;
        $display("non-blocking : a = %d, b = %d", a, b);


    end

endmodule
