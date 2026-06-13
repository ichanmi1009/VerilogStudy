`timescale 1ns / 1ps

module spi_slave (

    input  logic sclk,
    input  logic mosi,
    output logic miso,
    input  logic ss_n,

    input logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic done,
    output logic busy
);

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        DATA,
        STOP
    } spi_state_e;

    spi_state_e       state;

    logic       [7:0] tx_shift_reg;
    logic       [7:0] rx_shift_reg;
    logic       [2:0] bit_cnt;


    // receive
    always_ff @(posedge sclk or posedge ss_n) begin
        if (ss_n) begin
            state        <= IDLE;
            rx_shift_reg <= 0;
            bit_cnt      <= 0;
            done         <= 1'b0;
            busy         <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    state        <= DATA;
                    rx_shift_reg <= {rx_shift_reg[6:0], mosi};
                    bit_cnt      <= 0;
                    busy         <= 1'b1;
                    done         <= 1'b0;
                end
                DATA: begin
                    if (bit_cnt == 6) begin
                        rx_data <= {rx_shift_reg[6:0], mosi};
                        state   <= STOP;
                    end else begin
                        rx_shift_reg <= {rx_shift_reg[6:0], mosi};
                        bit_cnt <= bit_cnt + 1;
                    end
                end
                STOP: begin
                    state   <= IDLE;
                    bit_cnt <= 0;
                    done    <= 1'b1;
                    busy    <= 1'b0;
                end
                default: state <= IDLE;
            endcase
        end
    end




    // send
    always_ff @(negedge sclk or negedge ss_n) begin
        if (!ss_n && state == IDLE) begin
            tx_shift_reg <= tx_data;
        end else if (!ss_n && state == DATA) begin
            miso <= tx_shift_reg[7];
            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
        end
    end
    assign miso = (!ss_n) ? tx_shift_reg[7] : 1'b1;

endmodule

