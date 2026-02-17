`timescale 1ns/1ps
module bus_model_tb;
    wire sda;  // open-drain bus

    // 兩個 device 各自有 output enable 和 data
    reg  device_a_oe;
    reg  device_a_data;
    reg  device_b_oe;
    reg  device_b_data;
