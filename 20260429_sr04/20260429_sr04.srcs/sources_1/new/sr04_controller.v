`timescale 1ns / 1ps

module TOP_sr04_controller (
    input        clk,
    input        rst,
    input        btnR,
    input        echo,
    output       trig,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);

endmodule

module sr04_controller (
    input        clk,
    input        rst,
    input        sr04_start,
    input        tick_us,
    input        echo,
    output       trig,
    output [8:0] distance
);
endmodule

module tick_gen_us (
    input      clk,
    input      rst,
    output reg tick_us
);

    parameter F_COUNT = 100_000_000 / 1_000_000;  //1us
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_us     <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_us     <= 1'b1;
            end else begin
                tick_us <= 1'b0;
            end
        end
    end

endmodule
