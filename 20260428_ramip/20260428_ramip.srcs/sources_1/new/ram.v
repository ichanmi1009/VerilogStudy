`timescale 1ns / 1ps

module ram (

    input        clk,
    input  [7:0] addr,
    input  [7:0] wdata,
    input        we,
    output [7:0] rdata   // 아까는 순차회로안에 있어서 reg rdata
);

    reg [7:0] ram[0:255];  // ram 4비트 16개->255로 수정 lutram이 생김

    always @(posedge clk) begin
        if (we) begin
            // write to ram
            ram[addr] <= wdata;
        end
        // else begin
        //     // read from ram
        //     // SL output
        //     rdata <= ram[addr];
        // end
    end

    // CL output
    assign rdata = ram[addr];


endmodule
