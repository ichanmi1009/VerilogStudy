`timescale 1ns / 1ps

module uart_rx_sv (
    input  logic       clk,
    input  logic       rst,
    input  logic       rx,
    output logic [7:0] rx_data,
    output logic       rx_done
);

    logic b_tick;

    baud_tick_gen_rx U_BAUD_TICK_GEN_RX (
        .*,
        .o_b_tick(b_tick)
    );

    typedef enum {
        IDLE  = 0,
        START,
        DATA,
        STOP
    } state_t;
    state_t c_state, n_state;

    //parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;
    //logic [1:0] c_state, n_state;
    logic [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    logic [2:0] bit_cnt_reg, bit_cnt_next;
    logic [7:0] data_reg, data_next;
    logic rx_done_reg, rx_done_next;
    logic rx_sync1, rx_sync2;


    assign rx_done = rx_done_reg;
    assign rx_data = data_reg;


    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state        <= IDLE;
            b_tick_cnt_reg <= 0;
            bit_cnt_reg    <= 0;
            data_reg       <= 8'h00;
            rx_done_reg    <= 1'b0;
            rx_sync1       <= 0;
            rx_sync2       <= 0;
        end else begin
            c_state        <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            data_reg       <= data_next;
            rx_done_reg    <= rx_done_next;
            rx_sync1       <= rx;
            rx_sync2       <= rx_sync1;
        end
    end

    // next, output CL
    always_comb begin
        n_state = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next = bit_cnt_reg;
        data_next = data_reg;
        rx_done_next = rx_done_reg;
        case (c_state)
            IDLE: begin
                rx_done_next = 0;
                if (b_tick && (!rx_sync2)) begin
                    b_tick_cnt_next = 0;
                    n_state         = START;
                end
            end
            START: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 7) begin
                        b_tick_cnt_next = 0;
                        bit_cnt_next    = 0;
                        n_state         = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        data_next = {rx_sync2, data_reg[7:1]};
                        b_tick_cnt_next = 0;
                        if (bit_cnt_reg == 7) begin
                            b_tick_cnt_next = 0;
                            bit_cnt_next = 0;
                            n_state = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end


            STOP: begin
                if (b_tick) begin
                    if ((b_tick_cnt_reg == 23) || ((b_tick_cnt_reg > 16) && !rx_sync2)) begin
                        rx_done_next = 1'b1;
                        n_state = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

        endcase
    end


endmodule


module baud_tick_gen_rx (
    input      clk,
    input      rst,
    output reg o_b_tick
);
    parameter F_COUNT = 100_000_000 / (9600 * 16);
    parameter WIDTH = $clog2(F_COUNT) - 1;

    reg [WIDTH:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_b_tick    <= 0 ;
        end else begin
            // period 9600 hz
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                o_b_tick <= 1'b1;
            end else begin
                o_b_tick <= 1'b0;
            end
        end
    end

endmodule
