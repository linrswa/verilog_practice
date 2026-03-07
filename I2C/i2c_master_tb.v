`timescale 1ns / 1ps
module i2c_master_tb;

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

  reg sda_slave_oe;
  reg done_seen;

  // 用 always block 把 done pulse 鎖住，方便事後檢查
  always @(posedge clk) begin
    if (done) done_seen <= 1;
  end

  pullup (sda);
  pullup (scl);

  i2c_master #(
      .CLK_DIV(8)
  ) uut (
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

  assign sda = sda_slave_oe ? 1'b0 : 1'bz;  // 模擬 slave ACK/NACK
  task automatic setup;
    begin
      clk = 0;
      rst_n = 0;
      start = 0;
      slave_addr = 7'b1010000;  // Example slave address
      sda_slave_oe = 0;  // Slave releases SDA (high impedance)
      data_in = 8'hA5;  // Example data to write
      num_bytes = 1;
      repeated_start = 0;

      // Reset the module
      #10 rst_n = 1;
    end
  endtask

  task automatic slave_ack_mock;
    begin
      repeat (8) @(posedge scl);
      @(negedge scl);
      repeat (2) @(posedge clk);
      sda_slave_oe = 1;  // Simulate slave ACK by pulling SDA low
      repeat (6) @(posedge clk);
      sda_slave_oe = 0;  // Release SDA after ACK
    end
  endtask

  task automatic slave_nack_mock;
    begin
      repeat (9) @(posedge scl);
      sda_slave_oe = 0;
    end
  endtask

  /////// Write Tests ///////

  task automatic write_test;
    integer err;
    begin
      $display("[TEST] Normal Write (both ACK)");
      done_seen = 0;
      err = 0;
      rw = 0;

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
      rw = 0;

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

  task automatic nack_on_write_test;
    integer err;
    begin
      $display("[TEST] NACK on Data");
      done_seen = 0;
      err = 0;
      rw = 0;

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
  task automatic multi_byte_write_test;
    integer err;
    begin
      $display("[TEST] Multi-byte Write (3 bytes)");
      done_seen = 0;
      err = 0;
      rw = 0;
      num_bytes = 3;
      data_in = 8'hA5;

      #20 start = 1;
      #10 start = 0;

      slave_ack_mock();        // Address ACK → data_buf = 0xA5
      data_in = 8'hB6;
      slave_ack_mock();        // Byte 0 (0xA5) ACK → data_buf = 0xB6
      data_in = 8'hC7;
      slave_ack_mock();        // Byte 1 (0xB6) ACK → data_buf = 0xC7
      slave_ack_mock();        // Byte 2 (0xC7) ACK → byte_count==2, STOP

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
      if (byte_count !== 4'd3) begin
        $display("  FAIL: byte_count = %0d, expected 3", byte_count);
        err = 1;
      end
      if (!err) $display("  PASS");
    end
  endtask
  ///////////////////////////

  task automatic slave_sda_mock;
    input [7:0] byte_in;
    integer i;
    begin
      for (i = 7; i >= 0; i = i - 1) begin
        @(negedge scl);
        repeat (2) @(posedge clk);
        sda_slave_oe = ~byte_in[i];  // 模擬 slave 傳送資料
        @(posedge scl);
      end
      @(negedge scl);
      sda_slave_oe = 0;  // Release SDA after sending byte
    end
  endtask

  //////// Read Tests ///////
  task automatic read_test;
    integer err;
    begin
      $display("[TEST] Normal Read");
      done_seen = 0;
      err = 0;
      rw = 1;

      #20 start = 1;
      #10 start = 0;

      slave_ack_mock();  // ACK for address
      slave_sda_mock(8'hAA);  // Mock slave sending data byte

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
      if (data_out !== 8'hAA) begin
        $display("  FAIL: data_out = %h, expected AA", data_out);
        err = 1;
      end
      if (!err) $display("  PASS");
    end
  endtask
  ///////////////////////////

  task automatic multi_byte_read_test;
    integer err;
    reg [7:0] cap0, cap1;
    begin
      $display("[TEST] Multi-byte Read (2 bytes)");
      done_seen = 0;
      err = 0;
      rw = 1;
      num_bytes = 2;

      #20 start = 1;
      #10 start = 0;

      slave_ack_mock();          // Address ACK

      fork
        // Slave 驅動：連續送 2 bytes
        begin
          slave_sda_mock(8'hAA);    // Byte 0
          slave_sda_mock(8'h55);    // Byte 1
        end
        // Capture：監聽 data_valid pulse
        begin
          @(posedge data_valid);
          cap0 = data_out;
          @(posedge data_valid);
          cap1 = data_out;
        end
      join

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
      if (cap0 !== 8'hAA) begin
        $display("  FAIL: byte 0 = %h, expected AA", cap0);
        err = 1;
      end
      if (cap1 !== 8'h55) begin
        $display("  FAIL: byte 1 = %h, expected 55", cap1);
        err = 1;
      end
      if (byte_count !== 4'd2) begin
        $display("  FAIL: byte_count = %0d, expected 2", byte_count);
        err = 1;
      end
      if (!err) $display("  PASS");
    end
  endtask
  ///////////////////////////

  ////// Repeated Start Tests //////
  task automatic repeated_start_test;
    integer err;
    begin
      $display("[TEST] Repeated Start");
      done_seen = 0;
      err = 0;
      repeated_start = 1;

      // First transaction (write)
      rw = 0;
      #20 start = 1;
      #10 start = 0;
      slave_ack_mock();
      slave_ack_mock();
      repeated_start = 0;  // Clear repeated start after use

      @(posedge scl);
      rw = 1;
      slave_ack_mock();
      slave_sda_mock(8'h55);


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
      if (data_out !== 8'h55) begin
        $display("  FAIL: data_out = %h, expected 55", data_out);
        err = 1;
      end
      if (!err) $display("  PASS");
    end
  endtask
  /////////////////////////////////

  initial begin
    $dumpfile("i2c_master_tb.vcd");
    $dumpvars(0, i2c_master_tb);
    setup();
    write_test();
    setup();
    nack_on_addr_test();
    setup();
    nack_on_write_test();
    setup();
    multi_byte_write_test();
    setup();
    read_test();
    setup();
    multi_byte_read_test();
    setup();
    repeated_start_test();
    $finish;
  end

  always #5 clk = ~clk;
endmodule
