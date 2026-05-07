//inout이라서 wire로 넣어주던가. 강제로 테스트벤치에서 값을 넣어주던가.dht
//싱크신호 잡지않아서 x,z 구간발생
//io_oe 센서쪽에서 끊어줘야함
`timescale 1ns / 1ps
module tb_dht11_fnd ();
    // 시뮬레이션 파라미터
    parameter [7:0] HUMI_INT = 8'd60;  // 습도 정수부
    parameter [7:0] TEMP_INT = 8'd25;  // 온도 정수부
    parameter [39:0] DATA_STREAM = {
        HUMI_INT, 8'h00, TEMP_INT, 8'h00, HUMI_INT + TEMP_INT
    };
    reg clk;
    reg rst;
    reg btn_R;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire led;
    wire dht11;

    // 
    reg dht_sensor_data;
    reg io_oe;
    wire valid;

    //  tb io mode 변환.
    assign dht11 = (io_oe) ? dht_sensor_data : 1'bz;

    dht11 dut (
        .clk(clk),
        .rst(rst),
        .btn_R(btn_R),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .led(led),
        .dht11(dht11)
    );

    /* dht11_controller dut (
        .clk        (clk),
        .rst        (rst),
        .dht11_start(btn_start),
        .tick_us    (w_tick_us),
        .humidity   (humidity),
        .temperature(temperature),
        .valid      (valid),        // for check sum valid가 1이면 led ()킴
        .check_led  (check_led),
        .dht11      (dht11)
    );*/

    /* tick_gen_us dut1 (
        .clk(clk),
        .rst(rst),
        .tick_us(w_tick_us)
    );*/

    always #5 clk = ~clk;
    integer i = 0;

    initial begin
        clk   = 0;
        rst   = 1;
        io_oe = 0;
        btn_R = 0;



        #100;
        rst = 0;
        #100;
        btn_R = 1;
        #1_000_000;
        btn_R = 0;
        #100;
        wait (!dht11);
        // 18msec 대기
        wait (dht11);
        #30000;
        // 입력 모드로 변환
        io_oe = 1;
        dht_sensor_data = 1'b0;
        #80000;
        dht_sensor_data = 1'b1;
        #80000;
        for (i = 39; i >= 0; i = i - 1) begin
            dht_sensor_data = 0;
            #50000;
            dht_sensor_data = 1'b1;
            #(DATA_STREAM[i] ? 70000 : 26000);

        end
        dht_sensor_data = 0;
        #50000;
        io_oe = 0;
        #50000;
        $stop;
    end




endmodule

