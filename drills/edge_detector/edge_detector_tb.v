`timescale 1ns / 1ps

module edge_detector_tb;
  reg  clk;
  reg  rst_n;
  reg  sig_in;

  wire rising_edge;
  wire falling_edge;

  edge_detector dut (
      .clk(clk),
      .rst_n(rst_n),
      .sig_in(sig_in),
      .rising_edge(rising_edge),
      .falling_edge(falling_edge)
  );

  always #5 clk = ~clk;  // 100MHz clock

  task automatic reset;
    begin
      rst_n = 1;
      #10 rst_n = 0;
      #10 rst_n = 1;
    end
  endtask

  initial begin
    $dumpfile("edge_detector_tb.vcd");
    $dumpvars(0, edge_detector_tb);
    $monitor("Time: %0t | sig_in: %b | rising_edge: %b | falling_edge: %b", $time, sig_in,
             rising_edge, falling_edge);

    clk = 0;
    sig_in = 0;
    reset();

    #10 sig_in = 0;
    #10 sig_in = 1;

    #10 sig_in = 1;
    #10 sig_in = 0;
    #10 reset();

    #10 sig_in = 0;
    #100;
    reset();

    // Test multiple edges
    #10 sig_in = 1;
    #10 sig_in = 0;
    #10 sig_in = 1;
    #10 sig_in = 0;
    #10 sig_in = 1;
    #10 sig_in = 0;

    $finish;
  end

endmodule
