`timescale 1ns / 1ps

module tb_top ();

    parameter [7:0] HUMI_INT = 8'd60;  // 습도 정수부
    parameter [7:0] TEMP_INT = 8'd25;  // 온도 정수부
    parameter [39:0] DATA_STREAM = {
        HUMI_INT, 8'h00, TEMP_INT, 8'h00, HUMI_INT + TEMP_INT
    };

    reg clk;
    reg rst;
    reg [3:0] sw;
    reg btn_R;
    reg btn_L;
    reg btn_U;
    reg btn_D;
    reg echo;
    wire [8:0] led;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire dht11;
    wire trig;

    reg dht_sensor_data;
    reg io_oe;

    assign dht11 = (io_oe) ? dht_sensor_data : 1'bz;

    top dut (
        .clk(clk),
        .rst(rst),
        .sw(sw),
        .btn_R(btn_R),
        .btn_L(btn_L),
        .btn_U(btn_U),
        .btn_D(btn_D),
        .echo(echo),
        .led(led),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .dht11(dht11),
        .trig(trig)
    );

    always #5 clk = ~clk;
    integer i;

    initial begin
        clk = 0;
        rst = 1;
        echo = 0;
        io_oe = 0;
        sw = 4'b0000;  // 시계 모드
        btn_R = 0;
        btn_L = 0;
        btn_U = 0;
        btn_D = 0;

        #20;
        rst = 0;
        sw  = 4'b0010;  // 초음파 모드
        #100;

        btn_R = 1;
        #1_000_000;
        btn_R = 0;
        #100;

        wait (trig);

        #500;
        echo = 1;
        #(232 * 1000 * 2);
        echo = 0;

        #2000000;

        $stop;

    end




    /*
        btn_R = 1;
        #1_000_000;
        btn_R = 0;
        #100;

        wait (trig);

        #500;
        echo = 1;
        #(232 * 1000 * 2);
        echo = 0;

        #2000000;

        $stop;

        //wait (!dht11);
        // 18msec 대기
        //wait (dht11);
        //#30000;
        // 입력 모드로 변환
        //io_oe = 1;
        //dht_sensor_data = 1'b0;
        //#80000;
        //dht_sensor_data = 1'b1;
        //#80000;
        //for (i = 39; i >= 0; i = i - 1) begin
        //    dht_sensor_data = 0;
        //    #50000;
        //    dht_sensor_data = 1'b1;
        //    #(DATA_STREAM[i] ? 70000 : 26000);
        //
        //end
        //dht_sensor_data = 0;
        //#50000;
        //io_oe = 0;
        //#50000;
        //$stop;




    end
*/
endmodule
