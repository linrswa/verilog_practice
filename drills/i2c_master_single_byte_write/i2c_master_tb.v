`timescale 1ns / 1ps
module i2c_master_tb;

    reg clk;
    reg rst_n;
    reg start;
    reg [6:0] slave_addr;
    reg [7:0] data_in;
    wire busy;
    wire done;
    wire ack_error;
    wire [7:0] data_out;
    wire sda;
    wire scl;

    reg sda_slave_oe;
    reg done_seen;

    // 用 always block 把 done pulse 鎖住，方便事後檢查
    always @(posedge clk) begin
        if (done) done_seen <= 1;
    end

    pullup (sda);
    pullup (scl);

    i2c_master #(
        .CLK_DIV(4)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .slave_addr(slave_addr),
        .data_in(data_in),
        .busy(busy),
        .done(done),
        .ack_error(ack_error),
        .sda(sda),
        .scl(scl)
    );

    assign sda = sda_slave_oe ? 1'b0 : 1'bz;  // 模擬 slave ACK/NACK
    task automatic setup;
        begin
            clk = 0;
            rst_n = 0;
            start = 0;
            slave_addr = 7'b1010000;  // Example slave address
            sda_slave_oe = 0;  // Slave releases SDA (high impedance)
            data_in = 8'hA5;  // Example data to write

            // Reset the module
            #10 rst_n = 1;
        end
    endtask

    task automatic slave_ack_mock;
        begin
            repeat (9) @(posedge scl);
            sda_slave_oe = 1;  // Simulate slave ACK by pulling SDA low
            @(negedge scl);
            sda_slave_oe = 0;  // Release SDA after ACK
        end
    endtask

    task automatic slave_nack_mock;
        begin
            repeat (9) @(posedge scl);
            sda_slave_oe = 0;
        end
    endtask

    task automatic ack_test;
        integer err;
        begin
            $display("[TEST] Normal Write (both ACK)");
            done_seen = 0;
            err = 0;

            #20 start = 1;
            #10 start = 0;

            slave_ack_mock();
            slave_ack_mock();

            #1000;
            if (!done_seen) begin
                $display("  FAIL: done never pulsed");
                err = 1;
            end
            if (ack_error !== 1'b0) begin
                $display("  FAIL: ack_error = %b, expected 0", ack_error);
                err = 1;
            end
            if (busy !== 1'b0) begin
                $display("  FAIL: busy = %b, expected 0", busy);
                err = 1;
            end
            if (!err) $display("  PASS");
        end
    endtask

    task automatic nack_on_addr_test;
        integer err;
        begin
            $display("[TEST] NACK on Address");
            done_seen = 0;
            err = 0;

            #20 start = 1;
            #10 start = 0;

            slave_nack_mock();
            #1000;
            if (!done_seen) begin
                $display("  FAIL: done never pulsed");
                err = 1;
            end
            if (ack_error !== 1'b1) begin
                $display("  FAIL: ack_error = %b, expected 1", ack_error);
                err = 1;
            end
            if (busy !== 1'b0) begin
                $display("  FAIL: busy = %b, expected 0", busy);
                err = 1;
            end
            if (!err) $display("  PASS");
        end
    endtask

    task automatic nack_on_data_test;
        integer err;
        begin
            $display("[TEST] NACK on Data");
            done_seen = 0;
            err = 0;

            #20 start = 1;
            #10 start = 0;

            slave_ack_mock();  // ACK for address, no ACK for data
            #1000;
            if (!done_seen) begin
                $display("  FAIL: done never pulsed");
                err = 1;
            end
            if (ack_error !== 1'b1) begin
                $display("  FAIL: ack_error = %b, expected 1", ack_error);
                err = 1;
            end
            if (busy !== 1'b0) begin
                $display("  FAIL: busy = %b, expected 0", busy);
                err = 1;
            end
            if (!err) $display("  PASS");
        end
    endtask

    initial begin
        $dumpfile("i2c_master_tb.vcd");
        $dumpvars(0, i2c_master_tb);
        setup();
        ack_test();
        setup();
        nack_on_addr_test();
        setup();
        nack_on_data_test();
        $finish;
    end

    always #5 clk = ~clk;
endmodule
