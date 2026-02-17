`timescale 1ns / 1ps

module clock_divider_tb;
reg clk;
reg rst_n;

genvar i;
generate
    for (i = 1; i < 3; i = i + 1) begin : gen_clock_dividers 
	wire clk_out;
	clock_divider #(.DIVISOR(2**i)) dut (
	    .clk(clk),
	    .rst_n(rst_n),
	    .clk_out(clk_out)
	);
    end
endgenerate

task reset;
    begin
	rst_n = 0;
	#5 rst_n = 1;
    end
endtask

initial begin
    $dumpfile("clock_divider_tb.vcd");
    $dumpvars(0, clock_divider_tb);
    clk = 0;
    rst_n = 0;
    #10 rst_n = 1; 
    #100 reset;
    #200 $finish;
end

always #5 clk = ~clk;

endmodule
