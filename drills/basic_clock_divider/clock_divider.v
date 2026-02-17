`timescale 1ns / 1ps
module clock_divider(
    input wire clk,     
    input wire rst_n,      
    output reg clk_out      
);

parameter DIVISOR = 4;
localparam COUNTER_WIDTH = $clog2(DIVISOR);
reg [COUNTER_WIDTH-1:0] counter;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
	counter <= 0;
	clk_out <= 0;
    end else if (counter == DIVISOR/2 - 1) begin
	clk_out <= ~clk_out; 
	counter <= 0;        
    end else  begin
	counter <= counter + 1;
    end
end

endmodule
