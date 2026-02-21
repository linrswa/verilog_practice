`timescale 1ns / 1ps
module shift_register_piso_tb;
    reg clk;
    reg rst_n;
    reg load;
    reg shift_en;
    reg [7:0] data_in;
    wire serial_out;
    wire done;

    shift_register_piso uut (
        .clk(clk),
        .rst_n(rst_n),
        .load(load),
        .shift_en(shift_en),
        .data_in(data_in),
        .serial_out(serial_out),
        .done(done)
    );


    task automatic reset;
        begin
            rst_n = 1;
            #10;
            rst_n = 0;
            #10;
            rst_n = 1;
        end
    endtask

    task automatic load_data(input reg [7:0] data);
        begin
            @(posedge clk);
            #1;
            data_in = data;
            load = 1;
            @(posedge clk);
            #1;
            load = 0;
        end
    endtask

    always #5 clk = ~clk;  // Clock generation

    initial begin
        $dumpfile("shift_register_piso_tb.vcd");
        $dumpvars(0, shift_register_piso_tb);
        $monitor(
            "Time: %0t | clk: %b | rst_n: %b | load: %b | shift_en: %b | data_in: %h | serial_out: %b | done: %b",
            $time, clk, rst_n, load, shift_en, data_in, serial_out, done);
        clk = 0;
        rst_n = 0;
        load = 0;
        shift_en = 0;
        data_in = 0;

        reset;
        #10 load_data(8'hA5);  // Test data (10100101)
        shift_en = 1;
        #100 shift_en = 0;
        #10 reset;
        #10 load_data(8'h3C);  // Another test data (00111100)
        shift_en = 1;
        #30 load_data(8'hF0);  // Load new data while shifting
        #100 shift_en = 0;
        #10 $finish;
    end

endmodule
