`timescale 1ns / 1ps

module clock_divider_tb;
reg clk;
reg rst_n;
wire clk_out;

clock_divider #(.DIVISOR(4)) dut (
    .clk(clk),
    .rst_n(rst_n),
    .clk_out(clk_out)
);

task reset;
    begin
	rst_n = 0;
	#5 rst_n = 1;
    end
endtask

initial begin
    clk = 0;
    rst_n = 0;
    #10 rst_n = 1; 
end

always #5 clk = ~clk;

initial begin
    $dumpfile("clock_divider_tb.vcd");
    $dumpvars(0, clock_divider_tb);
    #200 $finish;
end

initial begin
    #100 reset;
end

endmodule
