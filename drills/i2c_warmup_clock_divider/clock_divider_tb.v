`timescale 1ns / 1ps

module clock_divider_tb;
    reg clk;
    reg rst_n;
    reg enable;
    wire scl;
    wire scl_mid_low;
    wire scl_mid_high;

    clock_divider #(.DIV_COUNT(4)) uut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .scl(scl),
        .scl_mid_low(scl_mid_low),
        .scl_mid_high(scl_mid_high)
    );

    always #10 clk = ~clk; // 產生 50 MHz 的時鐘

    initial begin
        $dumpfile("clock_divider_tb.vcd");
        $dumpvars(0, clock_divider_tb);
        clk = 0;
        rst_n = 0;
        enable = 0;

        #10 rst_n = 1;

        #10 enable = 1;

        #500;

        #10 enable = 0;

        #50;

        #10 enable = 1;

        #500;

        $finish; // 結束模擬
    end


endmodule
