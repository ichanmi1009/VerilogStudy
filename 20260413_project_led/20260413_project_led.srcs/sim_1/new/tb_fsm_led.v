`timescale 1ns / 1ps

module tb_fsm_led ();

    reg clk, rst;
    reg  [2:0] sw;
    wire [2:0] led;

    fsm_led dut (
        .clk(clk),
        .rst(rst),
        .sw (sw),
        .led(led)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1'b1;
        // reset
        #20;
        rst = 1'b0;

        //state a->b
        sw  = 3'b001;
        // wait : next positive clock
        @(posedge clk);
        @(posedge clk);

        //b->c
        sw = 3'b010;
        @(posedge clk);
        @(posedge clk);

        //c->d
        sw = 3'b100;
        @(posedge clk);
        @(posedge clk);

        //d->a
        sw = 3'b000;
        @(posedge clk);
        @(posedge clk);

        //a->c
        sw = 3'b010;
        @(posedge clk);
        @(posedge clk);

        //c->d
        sw = 3'b100;
        @(posedge clk);
        @(posedge clk);

        //d->e
        sw = 3'b111;
        @(posedge clk);
        @(posedge clk);

        //e->a
        sw = 3'b000;
        @(posedge clk);
        @(posedge clk);

        $stop;

    end

endmodule
