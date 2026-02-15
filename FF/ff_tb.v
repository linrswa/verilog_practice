// ff_tb.v - testbench that generates VCD (clear reset behavior)
`timescale 1ns/1ps

module ff_tb;

  reg  clk;
  reg  rst;
  reg  d;
  wire q;

  // DUT
  ff dut (
    .clk(clk),
    .rst(rst),
    .d(d),
    .q(q)
  );

  // clock: 10ns period, posedge at 5,15,25,...
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // VCD dump
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, ff_tb);
  end

  initial begin
    // 先讓 reset 作用一下
    rst = 1'b1;
    d   = 1'b0;

    // 釋放 reset（你要看的 1 -> 0）
    #12 rst = 1'b0;

    // 讓 d=1，等下一個 posedge（15ns）後 q 會變 1
    #1  d = 1'b1;

    // 等一段時間讓 q 確定被 clock 打成 1
    #20;  // 走過 15ns, 25ns

    // 在「非 clock 邊緣」把 reset 拉高：q 應該會立刻變 0（async reset）
    #3  rst = 1'b1;

    // 再把 reset 放掉：rst 會有清楚的 1 -> 0
    #4  rst = 1'b0;

    // reset 放掉後，再等下一個 posedge 才會重新載入 d
    #2  d = 1'b1;
    #20;

    $finish;
  end

endmodule