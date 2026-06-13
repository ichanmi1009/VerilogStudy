`timescale 1ns / 1ps

module tb_spi_master ();

    logic       clk;
    logic       reset;
    logic       start;
    logic       cpol;
    logic       cpha;
    logic [7:0] clk_div;
    logic [7:0] tx_data;
    logic       busy;
    logic [7:0] rx_data;
    logic       done;
    logic       sclk;
    logic       mosi;
    logic       miso;
    logic       ss_n;

    // logic       loop_wire;
    logic [7:0] slave_tx;
    logic [7:0] m_rx_data;
    logic [7:0] s_rx_data;
    logic       m_done;
    logic       m_busy;
    logic       s_done;
    logic       s_busy;

    initial clk = 0;
    always #5 clk = ~clk;

    spi_master dut (
        .clk    (clk),
        .reset  (reset),
        .start  (start),
        .cpol   (cpol),
        .cpha   (cpha),
        .clk_div(clk_div),
        .tx_data(tx_data),
        .busy   (m_busy),
        .rx_data(m_rx_data),
        .done   (m_done),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .ss_n   (ss_n)
    );

    spi_slave dut2 (
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .ss_n   (ss_n),
        .tx_data(slave_tx),
        .rx_data(s_rx_data),
        .done   (s_done),
        .busy   (s_busy)
    );
    task spi_set_mode(bit [1:0] mode);
        {cpol, cpha} = mode;
        @(posedge clk);
    endtask

    task spi_send_data(logic [7:0] data);
        tx_data = data;
        start   = 1'b1;
        @(posedge clk);
        start = 1'b0;
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
    endtask

    initial begin
        reset = 1;
        repeat (3) @(posedge clk);
        reset = 0;
        @(posedge clk);
        clk_div = 4;  // SCLK = 10Mhz -> (100Mhz / (10Mhz *2)) -1
        //slave_tx = 8'h55;
        @(posedge clk);

        spi_set_mode(0);
        for (int i = 0; i < 256; i++) begin
            slave_tx = -i;
            @(posedge clk);
            spi_send_data(i);

            if (s_rx_data == i) begin
                $display("RX PASS : master sent %h, slave got %h", i[7:0],
                         s_rx_data);
            end else begin
                $display("RX FAIL : slave sent %h, master got %h", i[7:0],
                         s_rx_data);
            end

            if (m_rx_data == -i) begin
                $display("TX PASS : slave sent %h, master got %h", -i[7:0],
                         m_rx_data);
            end else begin
                $display("TX FAIL : slave sent %h, master got %h", -i[7:0],
                         m_rx_data);
            end
        end
        /* spi_send_data(8'haa);
    
        spi_set_mode(0);
        spi_send_data(8'haa);

        spi_set_mode(0);
        spi_send_data(8'haa);

        spi_set_mode(0);
        spi_send_data(8'haa);*/

        #20;
        $finish;
    end


endmodule
