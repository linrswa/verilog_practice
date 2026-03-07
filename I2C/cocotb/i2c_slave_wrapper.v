`timescale 1ns / 1ps
// cocotb wrapper for i2c_slave
// 提供 master_scl_oe / master_sda_oe 讓 cocotb 模擬 master 端驅動
module i2c_slave_wrapper;

    reg clk;
    reg rst_n;

    // cocotb 透過這兩個 reg 模擬 master 端的 open-drain 驅動
    reg master_scl_oe;  // 1 = 拉低 SCL
    reg master_sda_oe;  // 1 = 拉低 SDA

    wire scl, sda;

    // DUT 輸出
    wire       busy;
    wire [7:0] reg_addr_out;
    wire [7:0] reg_data_out;
    wire       write_valid;

    // Open-drain bus + pullup
    assign scl = master_scl_oe ? 1'b0 : 1'bz;
    assign sda = master_sda_oe ? 1'b0 : 1'bz;
    pullup (scl);
    pullup (sda);

    // 固定 slave address
    parameter SLAVE_ADDR = 7'h50;

    i2c_slave dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .slave_addr   (SLAVE_ADDR),
        .busy         (busy),
        .reg_addr     (reg_addr_out),
        .reg_data_out (reg_data_out),
        .write_valid  (write_valid),
        .scl          (scl),
        .sda          (sda)
    );

    // Clock generation: 50MHz
    initial clk = 0;
    always #10 clk = ~clk;

    // VCD dump
    initial begin
        $dumpfile("i2c_slave_cocotb.vcd");
        $dumpvars(0, i2c_slave_wrapper);
    end

endmodule
