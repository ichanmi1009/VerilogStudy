`timescale 1ns / 1ps

module tb_register ();

    reg clk, rst;
    reg  [7:0] d;
    wire [7:0] q;

    register_8 dut (

        .clk(clk),
        .rst(rst),
        .d  (d),
        .q  (q)
    );

    always #5 clk = ~clk;

    integer i;

    initial begin
        clk = 0;
        rst = 1;
        d   = 8'h00;

        #10;
        rst = 0;
        @(posedge clk);
        #1;
        for (i = 0; i < 256; i = i + 1) begin
            d = i;
            #10;
        end

        @(negedge clk);
        $stop;
    end


endmodule
