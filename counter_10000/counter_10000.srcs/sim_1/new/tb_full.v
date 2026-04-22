`timescale 1ns / 1ps

module tb_full ();

    reg clk;
    reg rst;
    reg btnL;
    reg btnR;
    reg btnD;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;

    counter_10000 dut (
        .clk(clk),
        .rst(rst),
        .btnL(btnL),
        .btnR(btnR),
        .btnD(btnD),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

    always #5 clk = ~clk;

    initial begin
        clk  = 0;
        rst  = 1;
        btnL = 0;
        btnR = 0;
        btnD = 0;

        repeat (3) @(negedge clk);
        rst = 0;
        // run
        repeat (10000) @(negedge clk);
        btnR = 1;

        repeat (10000) @(negedge clk);
        btnR = 0;

        repeat (10) @(negedge clk);
        // stop
        btnR = 1;
        repeat (20000) @(negedge clk);
        btnR = 0;
        repeat (100000) @(negedge clk);

        // clear
        btnL = 1;
        repeat (100000) @(negedge clk);
        btnL = 0;

        // 결과 확인 후 종료
        repeat (100000) @(negedge clk);

        $stop;

    end

    /*
  always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst   = 1;
        i_btn = 0;

        repeat (3) @(negedge clk);
        rst = 0;
        #10 i_btn = 1;

        repeat (8000) @(negedge clk);

        i_btn = 0;
        #20;
        $stop;


    end
*/

endmodule
