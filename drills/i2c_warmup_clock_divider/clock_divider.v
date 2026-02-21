`timescale 1ns / 1ps

module clock_divider (
    input  wire clk,       // 系統時鐘（例如 50 MHz）
    input  wire rst_n,      // 非同步 reset（active low）
    input  wire enable,     // 致能信號（LOW 時 SCL 停在 HIGH）
    output reg  scl,        // 產生的 SCL 時鐘
    output wire scl_mid_low,// SCL LOW phase 的中間點（用於切換 SDA）
    output wire scl_mid_high// SCL HIGH phase 的中間點（用於取樣 SDA）
);

parameter integer DIV_COUNT = 250; // 每個 SCL 週期的半週期計數
localparam integer MidPoint = DIV_COUNT / 2 - 1;
reg [$clog2(DIV_COUNT)-1:0] counter;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 0;
        scl <= 1; // SCL 初始為 HIGH
    end else if (enable) begin
        if (counter == DIV_COUNT - 1) begin
            counter <= 0;
            scl <= ~scl; // 切換 SCL 狀態
        end else begin
            counter <= counter + 1;
        end
    end else begin
        counter <= 0;
        scl <= 1;
    end
end

assign scl_mid_low = (counter == MidPoint) && (scl == 0); // SCL LOW phase 的中間點
assign scl_mid_high = (counter == MidPoint) && (scl == 1);

endmodule
