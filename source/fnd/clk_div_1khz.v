module clk_div_1khz #(
    parameter DIV_COUNT = 50_000
)(
    input       clk,
    input       rst,
    output      o_1khz
);

    reg [$clog2(DIV_COUNT):0] counter_reg;
    reg o_1khz_reg;

    assign o_1khz = o_1khz_reg;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            counter_reg <= 0;
            o_1khz_reg  <= 1'b0;
        end
        else begin
            counter_reg <= counter_reg + 1'b1;
            if(counter_reg == (DIV_COUNT-1)) begin
                counter_reg <= 0;
                o_1khz_reg  <= ~o_1khz_reg;
            end
        end
    end

endmodule