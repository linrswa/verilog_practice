// ff.v - simple DFF with async active-high reset
`timescale 1ns/1ps

module ff (
  input  wire clk,
  input  wire rst,   // async reset, active-high
  input  wire d,
  output reg  q
);

  always @(posedge clk or posedge rst) begin
    if (rst) q <= 1'b0;
    else     q <= d;
  end

endmodule