`timescale 1ns / 1ps
module shift_register_piso (
    input  wire       clk,         // 系統時鐘
    input  wire       rst_n,       // 非同步 reset（active low）
    input  wire       load,        // 載入 parallel data（優先於 shift）
    input  wire       shift_en,    // shift 致能（每個 clock shift 一次）
    input  wire [7:0] data_in,     // 8-bit parallel 輸入
    output wire       serial_out,  // 串列輸出（MSB first）
    output wire       done         // 8 個 bit 都送完時拉高
);

    reg [7:0] shift_reg;  // 8-bit shift register
    reg [2:0] bit_count;  // 計數器，追蹤已經 shift 出多少 bit

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'b0;
            bit_count <= 3'd0;
        end else if (load) begin
            shift_reg <= data_in;
            bit_count <= 3'd0;
        end else if (shift_en && !done) begin
            shift_reg <= {shift_reg[6:0], 1'b0};
            bit_count <= bit_count + 1;
        end
    end

    assign done = (bit_count == 3'd7) && shift_en ;  // 當 shift 出 8 個 bit 時拉高 done
    assign serial_out = shift_reg[7];  // MSB first

endmodule
