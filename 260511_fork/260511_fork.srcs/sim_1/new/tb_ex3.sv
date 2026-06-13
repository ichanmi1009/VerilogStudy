`timescale 1ns / 1ps

module tb_ex3 ();

    initial begin
        #1 $display("%t : start fork - join", $time);

        fork
            // task A
            A_thread();
            // task B
            B_thread();
            // task C
            C_thread();
        join_any

        #10 $display("%t : end fork - join", $time);
        disable fork;
        $stop;
    end

    task A_thread();
        repeat (5) $display("%t : A thread", $time);
    endtask

    task B_thread();
        forever begin
            $display("%t : B thread", $time);
            #5;
        end
    endtask

    task C_thread();
        forever begin
            $display("%t : C thread", $time);
            #10;
        end
    endtask

endmodule
