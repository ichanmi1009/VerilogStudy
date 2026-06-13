`timescale 1ns / 1ps

module uart_tx_sv (
    input  logic       clk,
    input  logic       rst,
    input  logic       tx_start,  // start trigger
    input  logic [7:0] tx_data,
    input  logic       b_tick,
    output logic       tx,
    output logic       tx_busy
);

    typedef enum {
        IDLE  = 0,
        START,
        DATA,
        STOP
    } state_t;
    state_t c_state, n_state;

    logic tx_reg, tx_next;
    // tx data register
    logic [7:0] data_reg, data_next;
    logic [2:0] bit_cnt_reg, bit_cnt_next;  // bit count 
    logic [3:0] b_tick_cnt_reg, b_tick_cnt_next;
    logic tx_busy_reg, tx_busy_next;

    assign tx = tx_reg;
    assign tx_busy = tx_busy_reg;

    // state register
    // current : output, next : input
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state        <= IDLE;
            tx_reg         <= 1'b1;
            data_reg       <= 8'h00;
            bit_cnt_reg    <= 3'b000;
            b_tick_cnt_reg <= 4'h0;
            tx_busy_reg    <= 1'b0;
        end else begin
            c_state        <= n_state;
            tx_reg         <= tx_next;
            data_reg       <= data_next;
            bit_cnt_reg    <= bit_cnt_next;
            b_tick_cnt_reg <= b_tick_cnt_next;
            tx_busy_reg    <= tx_busy_next;
        end
    end

    // next st CL, output
    always_comb begin
        // current_state
        n_state         = c_state;  // n_state 
        tx_next         = tx_reg;  // tx output
        data_next       = data_reg;
        bit_cnt_next    = bit_cnt_reg;
        b_tick_cnt_next = b_tick_cnt_reg;
        tx_busy_next    = tx_busy_reg;
        case (c_state)
            IDLE: begin
                tx_next      = 1'b1;
                tx_busy_next = 1'b0;
                if (tx_start) begin
                    tx_busy_next    = 1'b1;
                    data_next = tx_data;
                    b_tick_cnt_next = 0;
                    n_state = START;
                end
            end

            START: begin
                tx_next = 1'b0;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        bit_cnt_next = 3'b000;  // 珥덇린�솕
                        n_state = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            DATA: begin

                // tx_next = data_reg[bit_cnt_reg]; PIPO, parallel output
                // to output from bit0 of data_reg
                tx_next = data_reg[0];  // PISO, serial output
                // right shift 1bit data register

                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;

                        if (bit_cnt_reg == 7) begin
                            n_state = STOP;
                        end else begin
                            data_next = {1'b0, data_reg[7:1]};
                            bit_cnt_next = bit_cnt_reg + 1;
                            n_state = DATA;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            STOP: begin
                tx_next = 1;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        tx_busy_next = 1'b0;
                        n_state = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

