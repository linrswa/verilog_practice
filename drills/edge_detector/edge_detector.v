`timescale 1ns / 1ps

module edge_detector (
    input  wire clk,
    input  wire rst_n,
    input  wire sig_in,
    output wire rising_edge,
    output wire falling_edge
);

  reg cycle_prev;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cycle_prev <= 0;
    end else begin
      cycle_prev <= sig_in;
    end
  end

  assign rising_edge  = sig_in & !cycle_prev;
  assign falling_edge = !sig_in & cycle_prev;

endmodule
