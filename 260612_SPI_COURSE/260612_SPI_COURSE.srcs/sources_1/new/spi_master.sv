`timescale 1ns / 1ps

module spi_master (
    // global signals
    input  logic       clk,
    input  logic       reset,
    // internal signals
    input  logic       start,
    input  logic       cpol,     // clock polarity
    input  logic [7:0] clk_div,  // SCLK 속도 계산용 분주값
    input  logic [7:0] tx_data,
    output logic       busy,
    output logic [7:0] rx_data,
    output logic       done,
    // external signals
    output logic       sclk,
    output logic       mosi,
    input  logic       miso,
    output logic       ss_n
);

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START,
        DATA,
        STOP
    } spi_state_e;

    spi_state_e state;

    logic [7:0] div_cnt;
    logic [7:0] clk_div_r;
    logic half_tick;
    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic [2:0] bit_cnt;
    logic step;
    logic cpol_r;
    logic sclk_r;

    assign sclk = sclk_r;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            div_cnt   <= 0;
            half_tick <= 1'b0;
        end else begin
            if (state == DATA) begin
                if (div_cnt == clk_div_r) begin
                    div_cnt   <= 0;
                    half_tick <= 1'b1;
                end else begin
                    div_cnt   <= div_cnt + 1;
                    half_tick <= 1'b0;
                end
            end else begin
                div_cnt   <= 0;
                half_tick <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            mosi         <= 1'b1;
            ss_n         <= 1'b1;
            busy         <= 1'b0;
            done         <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            bit_cnt      <= 0;
            rx_data      <= 0;
            sclk_r       <= cpol;
            cpol_r       <= 1'b0;
            clk_div_r    <= 0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    mosi   <= 1'b1;
                    ss_n   <= 1'b1;
                    sclk_r <= cpol;
                    if (start) begin
                        state        <= START;
                        cpol_r       <= cpol;
                        tx_shift_reg <= tx_data;  // latching
                        clk_div_r    <= clk_div;  // latching
                        bit_cnt      <= 0;
                        busy         <= 1'b1;
                        step         <= 1'b0;
                        ss_n         <= 1'b0;
                    end
                end
                START: begin
                    mosi         <= tx_shift_reg[7];
                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                    state        <= DATA;
                end
                DATA: begin
                    if (half_tick) begin
                        sclk_r <= ~sclk_r;
                        if (step == 0) begin  // -- 첫번째 에지
                            step         <= 1'b1;
                            rx_shift_reg <= {rx_shift_reg[6:0], miso};
                        end else begin  // -- 두번째 에지
                            step <= 1'b0;
                            if (bit_cnt < 7) begin
                                mosi         <= tx_shift_reg[7];
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                bit_cnt      <= bit_cnt + 1;
                            end else begin
                                state   <= STOP;
                                rx_data <= rx_shift_reg;
                            end
                        end
                    end
                end
                STOP: begin
                    sclk_r <= cpol_r;
                    ss_n   <= 1'b1;
                    done   <= 1'b1;
                    busy   <= 1'b0;
                    mosi   <= 1'b1;
                    state  <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
