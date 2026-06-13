`timescale 1ns / 1ps
`include "define.vh"

module data_mem (
    input  logic        clk,
    input  logic        dwe,
    input  logic [ 2:0] mem_mode,
    input  logic [31:0] daddr,
    input  logic [31:0] dwdata,
    output logic [31:0] drdata
);

    logic [31:0] data_ram[0:63];  // 입출력 구조, 255에서 63으로 줄임

    //initial begin
    // IL-TYPE 
    //data_ram[4] = 32'h55aacc11;
    // R-TYPE
    //data_ram[4] = 32'd0;
    //data_ram[5] = 32'd0;
    //data_ram[6] = 32'd0;
    //end

    always_ff @(posedge clk) begin
        if (dwe) begin
            case (mem_mode)
                // sw : 4씩 증가, sh : 2씩 증가, sb : 1씩 증가(byte 단위 access)
                // 1. sw를 데이터 메모리에 집어넣는 동작
                `SW: begin  // SW
                    data_ram[daddr[31:2]] <= dwdata;
                end
                `SH: begin
                    case (daddr[1])
                        1'b0: data_ram[daddr[31:2]][15:0] <= dwdata[15:0];
                        1'b1: data_ram[daddr[31:2]][31:16] <= dwdata[15:0];
                    endcase
                end
                `SB: begin
                    case (daddr[1:0])
                        2'b00: data_ram[daddr[31:2]][7:0] <= dwdata[7:0];
                        2'b01: data_ram[daddr[31:2]][15:8] <= dwdata[7:0];
                        2'b10: data_ram[daddr[31:2]][23:16] <= dwdata[7:0];
                        2'b11: data_ram[daddr[31:2]][31:24] <= dwdata[7:0];
                    endcase
                end
            endcase
        end
    end

    // assign drdata = data_ram[daddr[31:2]];

    // 내가 추가한 것
    always_comb begin
        drdata = 32'b0;
        if (dwe == 0) begin
            case (mem_mode)
                `LW: begin  // SW
                    drdata = data_ram[daddr[31:2]];
                end
                `LH: begin  // sign extend
                    case (daddr[1])
                        1'b0:
                        drdata = {
                            {16{data_ram[daddr[31:2]][15]}},
                            data_ram[daddr[31:2]][15:0]
                        };
                        1'b1:
                        drdata = {
                            {16{data_ram[daddr[31:2]][31]}},
                            data_ram[daddr[31:2]][31:16]
                        };
                    endcase
                end
                `LHU: begin
                    case (daddr[1])
                        1'b0:
                        drdata = {{16{1'b0}}, data_ram[daddr[31:2]][15:0]};
                        1'b1:
                        drdata = {{16{1'b0}}, data_ram[daddr[31:2]][31:16]};
                    endcase
                end
                `LB: begin
                    case (daddr[1:0])
                        2'b00:
                        drdata = {
                            {24{data_ram[daddr[31:2]][7]}},
                            data_ram[daddr[31:2]][7:0]
                        };
                        2'b01:
                        drdata = {
                            {24{data_ram[daddr[31:2]][15]}},
                            data_ram[daddr[31:2]][15:8]
                        };
                        2'b10:
                        drdata = {
                            {24{data_ram[daddr[31:2]][23]}},
                            data_ram[daddr[31:2]][23:16]
                        };
                        2'b11:
                        drdata = {
                            {24{data_ram[daddr[31:2]][31]}},
                            data_ram[daddr[31:2]][31:24]
                        };
                    endcase
                end
                `LBU: begin
                    case (daddr[1:0])
                        2'b00:
                        drdata = {{24{1'b0}}, data_ram[daddr[31:2]][7:0]};
                        2'b01:
                        drdata = {{24{1'b0}}, data_ram[daddr[31:2]][15:8]};
                        2'b10:
                        drdata = {{24{1'b0}}, data_ram[daddr[31:2]][23:16]};
                        2'b11:
                        drdata = {{24{1'b0}}, data_ram[daddr[31:2]][31:24]};
                    endcase
                end
            endcase
        end
    end

endmodule
