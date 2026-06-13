`timescale 1ns / 1ps

module tb_i2c_master ();

    logic       clk;
    logic       reset;
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic       ack_in;
    logic       ack_out;
    logic       busy;
    logic       done;
    logic       scl;
    logic       sda_o;
    logic       sda_i;

    I2C_Master dut (
        .clk(clk),
        .reset(reset),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read(cmd_read),
        .cmd_stop(cmd_stop),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .ack_in(ack_in),
        .ack_out(ack_out),
        .busy(busy),
        .done(done),
        .scl(scl),
        .sda_o(sda_o),
        .sda_i(sda_i)
    );

endmodule
