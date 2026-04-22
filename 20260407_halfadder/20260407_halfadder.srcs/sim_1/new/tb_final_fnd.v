`timescale 1ns / 1ps

module tb_final_fnd ();
    reg [7:0] a, b;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire led;

    integer i, j;

    adder_fnd dut (
        .a(a),
        .b(b),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .led(led)
    );

    initial begin
        i = 0;
        j = 0;
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a = i;
                b = j;
                #10;
            end
        end
        $stop;
    end

endmodule
