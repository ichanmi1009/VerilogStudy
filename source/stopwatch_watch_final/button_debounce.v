`timescale 1ns / 1ps

module button_debounce (
    input  clk,
    input  rst,
    input  i_btn,
    output o_btn
);
    // clock devider
    // 100Mhz -> 100KHz // 10MHZ 한주기 0.1초 100 0.01초 // 시뮬레이션 용으로 10MHZ 사용
    parameter F_COUNT = 100000000 / 100000;
    reg [$clog2(F_COUNT)-1:0] r_counter;
    reg clk_100khz;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            clk_100khz <= 1'b0;
            r_counter  <= 0;
        end else begin
            r_counter <= r_counter + 1;
            if (r_counter == F_COUNT - 1) begin
                r_counter  <= 0;
                clk_100khz <= 1'b1;
            end else begin
                clk_100khz <= 1'b0;
            end
        end
    end


    // syncronizer
    reg [7:0] sync_reg, sync_next;
    reg  edge_reg;
    wire debounce;

    //클럭디바이더 나중에 넣고 posedge clk에 반영하면 됨 바로밑에

    always @(posedge clk_100khz, posedge rst) begin
        if (rst) begin
            sync_reg <= 0;
        end else begin
            sync_reg <= sync_next;
        end
    end

    always @(*) begin
        sync_next = {i_btn, sync_reg[7:1]};
        // sync_next = {sync_reg[6:0], i_btn};, 시프트 넣어도 됌
    end

    // 8input to 1output and gate
    assign debounce = &sync_reg;

    // rising edge detect
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end

    assign o_btn = debounce & (~edge_reg);

endmodule