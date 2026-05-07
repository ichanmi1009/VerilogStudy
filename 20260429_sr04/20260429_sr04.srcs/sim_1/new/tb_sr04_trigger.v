`timescale 1ns / 1ps

module tb_sr04_trigger ();

    parameter US_DELAY = 1000, MS_DELAY = 1_000_000;  //1000n

    reg clk, rst, sr04_start, echo;
    wire trig;
    wire [8:0] distance;
    wire w_tick_us, w_tick_58us;


    tick_gen_us dut2 (
        .clk(clk),
        .rst(rst),
        .tick_us(w_tick_us)
    );

    tick_gen_58us dut3 (
        .clk(clk),
        .rst(rst),
        .tick_58us(w_tick_58us)
    );

    sr04_controller dut (
        .clk(clk),
        .rst(rst),
        .sr04_start(sr04_start),
        .tick_us(w_tick_us),
        .tick_58us(w_tick_58us),
        .echo(echo),
        .trig(trig),
        .distance(distance)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        sr04_start = 0;
        echo = 0;
        #20 rst = 0;

        // start sr04
        @(posedge clk);
        sr04_start = 1;
        @(posedge clk);
        sr04_start = 0;
        //#(US_DELAY * 20); or @(negedge trig);
        // echo response
        #(US_DELAY * 20);
        echo = 1;
        #(MS_DELAY * 10);
        echo = 0;

        $stop;


    end


endmodule
