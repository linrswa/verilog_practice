`timescale 1ns / 1ps
// cocotb wrapper for i2c_master
// 提供 slave_sda_oe 讓 cocotb 模擬 slave 的 ACK/data 驅動
module i2c_master_wrapper;

    reg clk;
    reg rst_n;
    reg start;
    reg rw;
    reg [6:0] slave_addr;
    reg [7:0] data_in;
    reg [3:0] num_bytes;
    reg repeated_start;

    wire busy;
    wire done;
    wire ack_error;
    wire [7:0] data_out;
    wire data_valid;
    wire [3:0] byte_count;

    wire sda;
    wire scl;

    // cocotb 透過這個 reg 控制 slave 端的 SDA
    reg slave_sda_oe;  // 1 = 拉低 SDA（模擬 slave ACK 或 data bit 0）

    pullup (sda);
    pullup (scl);

    // slave 端的 open-drain 驅動
    assign sda = slave_sda_oe ? 1'b0 : 1'bz;

    i2c_master #(
        .CLK_DIV(8)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .rw(rw),
        .slave_addr(slave_addr),
        .data_in(data_in),
        .num_bytes(num_bytes),
        .repeated_start(repeated_start),
        .busy(busy),
        .done(done),
        .ack_error(ack_error),
        .data_out(data_out),
        .data_valid(data_valid),
        .byte_count(byte_count),
        .sda(sda),
        .scl(scl)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;  // 100MHz

    // VCD dump
    initial begin
        $dumpfile("i2c_master_cocotb.vcd");
        $dumpvars(0, i2c_master_wrapper);
    end

endmodule
