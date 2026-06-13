`timescale 1ns / 1ps

module counter (
    input            clk,
    input            rst,
    input            load,
    input      [7:0] data_in,
    input            en,
    output     [7:0] count,
    output reg       tick
);

    reg [7:0] counter_reg;
    reg [7:0] max_reg;

    assign count = counter_reg;

    // load 시 최대 count 값 저장
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            max_reg <= 8'd0;
        end else if (load) begin
            max_reg <= data_in;  // 예: data_in = 03이면 max_reg = 03
        end
    end

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 8'd0;
            tick        <= 1'b0;
        end else begin
            tick <= 1'b0;  // 기본값: tick은 0
            if (en) begin
                // count가 max_reg에 도달한 다음 클럭에서 0으로 복귀
                if (counter_reg == max_reg) begin
                    counter_reg <= 8'd0;
                    tick        <= 1'b0;
                end  // 다음 count가 max_reg가 되는 순간 tick 발생
          else if (counter_reg == max_reg - 1) begin
                    counter_reg <= counter_reg + 1'b1;
                    tick        <= 1'b1;
                end else begin
                    counter_reg <= counter_reg + 1'b1;
                    tick        <= 1'b0;

                end
            end
        end
    end

    //// counter
    //always @(posedge clk or posedge rst) begin
    //    //if (rst) begin
    //    //    counter_reg <= 8'd0;
    //    //    tick        <= 1'b0;
    //    //end else begin
    //    //    tick <= 1'b0;  // 기본값: tick은 0
    //
    //
    //    if (rst) begin
    //        counter_reg <= 8'd0;
    //        //tick        <= 1'b0;
    //    end else begin
    //        //tick <= 1'b0;
    //        if (load) begin
    //            counter_reg <= 8'd0;  // load 시 카운터 리셋
    //        end else if (en) begin
    //            if (counter_reg == max_reg) begin
    //                counter_reg <= 8'd0;
    //                //tick        <= 1'b1;
    //            end else begin
    //                counter_reg <= counter_reg + 1;
    //            end
    //        end
    //    end
    //end


endmodule

/*`timescale 1ns / 1ps

module counter (
    input            clk,
    input            rst,
    input            load,
    input      [7:0] data_in,
    input            en,
    output     [7:0] count,
    output reg       tick
);
    reg [7:0] counter_reg;
    reg [7:0] max_reg;

    assign count = counter_reg;

    // max_reg: load 시 data_in 저장
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            max_reg <= 8'd0;
        end else if (load) begin
            max_reg <= data_in;  // 03h 저장
        end
    end

    // counter
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 8'd0;
            tick        <= 1'b0;
        end else begin
            tick <= 1'b0;  // 기본값
            if (en) begin
                if (counter_reg == max_reg - 1) begin
                    counter_reg <= 8'd0;  // 03h → 00h 순환
                    tick        <= 1'b1;  // 펄스 발생
                end else begin
                    counter_reg <= counter_reg + 1;
                end
            end
        end
    end

endmodule
*/
