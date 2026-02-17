`timescale 1ns / 1ps
module bus_model_tb;
    wire sda;  // open-drain bus
    pullup (sda);  // 模擬上拉電阻

    // 兩個 device 各自有 output enable 和 data
    reg device_a_oe;
    reg device_a_data;
    reg device_b_oe;
    reg device_b_data;

    open_drain_output device_a (
        .data_out(device_a_data),
        .output_en(device_a_oe),
        .pad(sda)
    );

    open_drain_output device_b (
        .data_out(device_b_data),
        .output_en(device_b_oe),
        .pad(sda)
    );

    initial begin
        $dumpfile("bus_model_tb.vcd");
        $dumpvars(0, bus_model_tb);
        $monitor("Time: %0t | Device A: OE=%b, Data=%b | Device B: OE=%b, Data=%b | SDA=%b",
                 $time, device_a_oe, device_a_data, device_b_oe, device_b_data, sda);

        // 初始狀態：兩者都釋放
        device_a_oe   = 0;
        device_a_data = 1;  // A 釋放
        device_b_oe   = 0;
        device_b_data = 1;  // B 釋放
        #10;
        // A 拉低
        device_a_oe   = 1;
        device_a_data = 0;  // A 拉低
        device_b_oe   = 0;
        device_b_data = 1;  // B 釋放
        #10;
        // B 拉低
        device_a_oe   = 0;
        device_a_data = 1;  // A 釋放
        device_b_oe   = 1;
        device_b_data = 0;  // B 拉低
        #10;
        // 兩者都拉低
        device_a_oe   = 1;
        device_a_data = 0;  // A 拉低
        device_b_oe   = 1;
        device_b_data = 0;  // B 拉低
        #10;
        // A 釋放 B 拉低
        device_a_oe   = 1;
        device_a_data = 1;  // A 釋放
        device_b_oe   = 1;
        device_b_data = 0;  // B 拉低
        #10;
        $finish;
    end

endmodule
