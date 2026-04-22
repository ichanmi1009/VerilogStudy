`timescale 1ns / 1ps

module mux_4x1 (
    input      [3:0] a,
    input      [3:0] b,
    input      [3:0] c,
    input      [3:0] d,
    input      [1:0] sel,
    output reg [3:0] mux_out
);
    always @(*) begin
        mux_out = 4'h0;
        if (sel == 2'b00) mux_out = a;
        if (sel == 2'b01) mux_out = b;
        if (sel == 2'b10) mux_out = c;
        if (sel == 2'b11) mux_out = d;
        else mux_out = 4'b0;
    end




    /* assign mux_out = (sel == 2'b00) ? a :
                     (sel == 2'b01) ? b :
                     (sel == 2'b10) ? c :
                     (sel == 2'b11) ? d : 4'b0;
    */

    /*    always @(*) begin
        if (sel == 2'b00) mux_out = a;
        else if (sel == 2'b01) mux_out = b;
        else if (sel == 2'b10) mux_out = c;
        else if (sel == 2'b11) mux_out = d;
        else mux_out = 4'b0;
        end
*/


endmodule
