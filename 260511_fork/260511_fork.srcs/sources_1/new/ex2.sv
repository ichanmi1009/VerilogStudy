`timescale 1ns / 1ps

module tb_ex2 ();

    task A_thread();
        $display("%t : A thread", $time);
    endtask
    task B_thread();
        $display("%t : B thread", $time);
    endtask
    task C_thread();
        $display("%t : C thread", $time);
    endtask

    initial begin
        #1 $display("%t : start fork - join", $time);

        fork
            // task A
            #10 A_thread();
            // task B
            #20 B_thread();
            // task C
            #15 C_thread();

        join_none

        #10 $display("%t : end fork - join", $time);

    end

endmodule
