`timescale 1ns/1ps

module vending_fsm_tb;
  reg clk;
  reg rst_n;
  reg coin5, coin10;
  wire vend, change;

  integer pass_count, fail_count;

  vending_fsm dut (
    .clk(clk),
    .rst_n(rst_n),
    .coin5(coin5),
    .coin10(coin10),
    .vend(vend),
    .change(change)
  );

    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock

    // 投幣 task：在 negedge 拉高，下一個 negedge 拉低，確保剛好 1 cycle
    task pulse_coin5;
    begin
        @(negedge clk); coin5 = 1;
        @(negedge clk); coin5 = 0;
    end
    endtask

    task pulse_coin10;
    begin
        @(negedge clk); coin10 = 1;
        @(negedge clk); coin10 = 0;
    end
    endtask

    // 等待 N 個 clock cycle（用 negedge 對齊）
    task wait_cycles(input integer n);
        integer i;
    begin
        for (i = 0; i < n; i = i + 1)
            @(negedge clk);
    end
    endtask

    // 驗證 task：檢查 vend/change 是否符合預期，且只維持 1 cycle
    task check_output(
        input exp_vend,
        input exp_change,
        input [79:0] test_name  // 10 chars max
    );
    begin
        // pulse task 回傳時已在 negedge，state 已在上一個 posedge 更新，
        // 組合輸出已有效，直接取樣即可
        if (vend !== exp_vend || change !== exp_change) begin
            $display("FAIL %0s: vend=%b change=%b (expected vend=%b change=%b)",
                     test_name, vend, change, exp_vend, exp_change);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS %0s: vend=%b change=%b", test_name, vend, change);
            pass_count = pass_count + 1;
        end

        // 確認下一個 cycle 輸出歸零（只維持 1 cycle）
        @(posedge clk);
        @(negedge clk);
        if (vend !== 1'b0 || change !== 1'b0) begin
            $display("FAIL %0s: output not cleared after 1 cycle (vend=%b change=%b)",
                     test_name, vend, change);
            fail_count = fail_count + 1;
        end
    end
    endtask

    initial begin
        $dumpfile("vending_fsm_tb.vcd");
        $dumpvars(0, vending_fsm_tb);

        pass_count = 0;
        fail_count = 0;

        // Reset
        rst_n = 0; coin5 = 0; coin10 = 0;
        wait_cycles(3);
        rst_n = 1;
        wait_cycles(1);

        // ============================================================
        // Case 1: 10 + 5 = 15 → vend only
        // ============================================================
        $display("\n--- Case 1: 10 + 5 ---");
        pulse_coin10;       // 累積 10 元
        pulse_coin5;        // 累積 15 元 → 進入 S_VEND
        check_output(1'b1, 1'b0, "Case1");

        wait_cycles(2);

        // ============================================================
        // Case 2: 5 + 10 = 15 → vend only
        // ============================================================
        $display("\n--- Case 2: 5 + 10 ---");
        pulse_coin5;        // 累積 5 元
        pulse_coin10;       // 累積 15 元 → 進入 S_VEND
        check_output(1'b1, 1'b0, "Case2");

        wait_cycles(2);

        // ============================================================
        // Case 3: 10 + 10 = 20 → vend + change
        // ============================================================
        $display("\n--- Case 3: 10 + 10 ---");
        pulse_coin10;       // 累積 10 元
        pulse_coin10;       // 累積 20 元 → 進入 S_VEND_CHANGE
        check_output(1'b1, 1'b1, "Case3");

        wait_cycles(2);

        // ============================================================
        // Case 4: 5 + 5 + 5 = 15 → vend only
        // ============================================================
        $display("\n--- Case 4: 5 + 5 + 5 ---");
        pulse_coin5;        // 累積 5 元
        pulse_coin5;        // 累積 10 元
        pulse_coin5;        // 累積 15 元 → 進入 S_VEND
        check_output(1'b1, 1'b0, "Case4");

        wait_cycles(2);

        // ============================================================
        // Case 5: 5 + 5 + 10 = 20 → vend + change
        // ============================================================
        $display("\n--- Case 5: 5 + 5 + 10 ---");
        pulse_coin5;        // 累積 5 元
        pulse_coin5;        // 累積 10 元
        pulse_coin10;       // 累積 20 元 → 進入 S_VEND_CHANGE
        check_output(1'b1, 1'b1, "Case5");

        wait_cycles(2);

        // ============================================================
        // Case 6: Reset 中途投幣後應歸零
        // ============================================================
        $display("\n--- Case 6: Reset mid-transaction ---");
        pulse_coin10;       // 累積 10 元
        @(negedge clk); rst_n = 0;  // 中途 reset
        wait_cycles(2);
        rst_n = 1;
        @(negedge clk);
        if (vend !== 1'b0 || change !== 1'b0) begin
            $display("FAIL Case6: outputs not zero after reset (vend=%b change=%b)",
                     vend, change);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS Case6: reset clears state correctly");
            pass_count = pass_count + 1;
        end
        // 確認 reset 後仍能正常運作
        pulse_coin10;
        pulse_coin5;
        check_output(1'b1, 1'b0, "Case6b");

        // ============================================================
        // Summary
        // ============================================================
        $display("\n============================");
        $display("  Results: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("============================\n");

        if (fail_count == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");

        $finish;
    end

endmodule
