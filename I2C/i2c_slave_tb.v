`timescale 1ns / 1ps

module i2c_slave_tb;
    // 參數
    parameter CLK_PERIOD = 20;         // 系統時鐘 50MHz
    parameter I2C_PERIOD = 1000;       // I2C SCL 全週期（~1MHz）
    parameter HALF       = I2C_PERIOD / 2;
    parameter QUARTER    = I2C_PERIOD / 4;
    parameter SLAVE_ADDR = 7'h50;      // 測試用 slave address
    parameter WRONG_ADDR = 7'h3A;      // 不匹配的 address

    // 訊號
    reg        clk, rst_n;
    wire       scl, sda;
    reg        master_scl_oe;          // 1 = 拉低 SCL
    reg        master_sda_oe;          // 1 = 拉低 SDA

    // DUT 輸出
    wire       busy;
    wire [7:0] reg_addr_out;
    wire [7:0] reg_data_out;
    wire       write_valid;

    // Open-drain bus + pullup
    assign scl = master_scl_oe ? 1'b0 : 1'bz;
    assign sda = master_sda_oe ? 1'b0 : 1'bz;
    pullup (scl);
    pullup (sda);

    // DUT
    i2c_slave uut (
        .clk          (clk),
        .rst_n        (rst_n),
        .slave_addr   (SLAVE_ADDR),
        .busy         (busy),
        .reg_addr     (reg_addr_out),
        .reg_data_out (reg_data_out),
        .write_valid  (write_valid),
        .scl          (scl),
        .sda          (sda)
    );

    // 系統時鐘
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // write_valid 脈衝計數（用來驗證寫入次數）
    integer write_valid_count;
    initial write_valid_count = 0;
    always @(posedge clk) begin
        if (write_valid) write_valid_count = write_valid_count + 1;
    end

    // 測試結果
    integer pass_count = 0;
    integer fail_count = 0;

    task check;
        input [255:0] name;
        input [7:0]   expected;
        input [7:0]   actual;
        begin
            if (expected === actual) begin
                $display("[PASS] %0s: expected=0x%02X, got=0x%02X", name, expected, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s: expected=0x%02X, got=0x%02X", name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_ack;
        input [255:0] name;
        input         expected_ack;
        input         actual_ack;
        begin
            if (expected_ack === actual_ack) begin
                $display("[PASS] %0s: ACK=%0b", name, actual_ack);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s: expected ACK=%0b, got ACK=%0b",
                         name, expected_ack, actual_ack);
                fail_count = fail_count + 1;
            end
        end
    endtask

    //==========================================================================
    // I2C Master Behavioral Tasks
    //==========================================================================

    // 產生 START condition（也可用於 Repeated Start）
    // SCL HIGH 時 SDA falling edge
    task i2c_start;
        begin
            master_sda_oe = 0;  // 釋放 SDA → HIGH
            master_scl_oe = 0;  // 釋放 SCL → HIGH
            #HALF;
            master_sda_oe = 1;  // SDA ↓（SCL 仍 HIGH）→ START
            #QUARTER;
            master_scl_oe = 1;  // SCL → LOW
            #QUARTER;
        end
    endtask

    // 產生 STOP condition
    // SCL HIGH 時 SDA rising edge
    task i2c_stop;
        begin
            master_sda_oe = 1;  // 確保 SDA = LOW
            #QUARTER;
            master_scl_oe = 0;  // SCL → HIGH
            #QUARTER;
            master_sda_oe = 0;  // SDA ↑（SCL 仍 HIGH）→ STOP
            #HALF;
        end
    endtask

    // 寫一個 byte，回傳 slave 的 ACK 狀態
    // ack = 1 表示 slave 回了 ACK（SDA = LOW）
    task i2c_write_byte;
        input  [7:0] data;
        output       ack;
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                // SCL LOW 時設定 SDA
                master_sda_oe = ~data[i];  // oe=1 → 拉低 SDA，oe=0 → 釋放（HIGH）
                #QUARTER;
                master_scl_oe = 0;         // SCL ↑
                #HALF;
                master_scl_oe = 1;         // SCL ↓
                #QUARTER;
            end
            // ACK phase：釋放 SDA 讓 slave 驅動
            master_sda_oe = 0;
            #QUARTER;
            master_scl_oe = 0;             // SCL ↑
            #QUARTER;
            ack = ~sda;                    // SDA=0 → ACK=1
            #QUARTER;
            master_scl_oe = 1;             // SCL ↓
            #QUARTER;
        end
    endtask

    // 讀一個 byte，Master 送 ACK 或 NACK
    // send_ack = 1 → ACK（繼續讀），0 → NACK（結束讀取）
    task i2c_read_byte;
        input        send_ack;
        output [7:0] data;
        integer i;
        begin
            master_sda_oe = 0;  // 釋放 SDA 讓 slave 驅動
            for (i = 7; i >= 0; i = i - 1) begin
                #QUARTER;
                master_scl_oe = 0;  // SCL ↑
                #QUARTER;
                data[i] = sda;     // Sample SDA
                #QUARTER;
                master_scl_oe = 1;  // SCL ↓
                #QUARTER;
            end
            // Master 送 ACK/NACK
            master_sda_oe = send_ack ? 1 : 0;  // ACK = 拉低 SDA，NACK = 釋放
            #QUARTER;
            master_scl_oe = 0;  // SCL ↑
            #HALF;
            master_scl_oe = 1;  // SCL ↓
            #QUARTER;
            master_sda_oe = 0;  // 釋放 SDA
        end
    endtask

    //==========================================================================
    // 測試主體
    //==========================================================================
    reg       ack;
    reg [7:0] read_data;

    initial begin
        $dumpfile("i2c_slave_tb.vcd");
        $dumpvars(0, i2c_slave_tb);

        // 初始化
        rst_n         = 0;
        master_scl_oe = 0;
        master_sda_oe = 0;
        #200;
        rst_n = 1;
        #205;  // 故意偏移 5ns，避免 SCL 邊緣剛好落在 posedge clk 上（race condition）

        //----------------------------------------------------------------------
        // Test 1: Single byte write — 寫 0xA5 到 register 0x00
        //----------------------------------------------------------------------
        $display("\n=== Test 1: Single byte write ===");
        i2c_start;
        i2c_write_byte({SLAVE_ADDR, 1'b0}, ack);  // Address + Write
        check_ack("T1 addr ACK", 1, ack);
        i2c_write_byte(8'h00, ack);                // Register address = 0x00
        check_ack("T1 reg_addr ACK", 1, ack);
        i2c_write_byte(8'hA5, ack);                // Data = 0xA5
        check_ack("T1 data ACK", 1, ack);
        i2c_stop;
        #(I2C_PERIOD);
        check("T1 reg[0x00]", 8'hA5, uut.register_file[0]);

        //----------------------------------------------------------------------
        // Test 2: Multi-byte write — 寫 0x11, 0x22 到 register 0x02, 0x03
        //----------------------------------------------------------------------
        $display("\n=== Test 2: Multi-byte write (auto-increment) ===");
        i2c_start;
        i2c_write_byte({SLAVE_ADDR, 1'b0}, ack);
        check_ack("T2 addr ACK", 1, ack);
        i2c_write_byte(8'h02, ack);                // Register address = 0x02
        check_ack("T2 reg_addr ACK", 1, ack);
        i2c_write_byte(8'h11, ack);                // Data → reg[0x02]
        check_ack("T2 data1 ACK", 1, ack);
        i2c_write_byte(8'h22, ack);                // Data → reg[0x03]
        check_ack("T2 data2 ACK", 1, ack);
        i2c_stop;
        #(I2C_PERIOD);
        check("T2 reg[0x02]", 8'h11, uut.register_file[2]);
        check("T2 reg[0x03]", 8'h22, uut.register_file[3]);

        // ----------------------------------------------------------------------
        // Test 3: Single byte read — 讀回 reg[0x00] = 0xA5（Test 1 寫入的）
        // 方法：先用 write transaction 設定 register pointer，再讀
        //----------------------------------------------------------------------
        $display("\n=== Test 3: Single byte read ===");
        // 設定 register pointer 到 0x00
        i2c_start;
        i2c_write_byte({SLAVE_ADDR, 1'b0}, ack);
        check_ack("T3 write addr ACK", 1, ack);
        i2c_write_byte(8'h00, ack);                // 設定 reg pointer = 0x00
        check_ack("T3 reg_addr ACK", 1, ack);
        i2c_stop;
        #(I2C_PERIOD);
        // 讀取
        i2c_start;
        i2c_write_byte({SLAVE_ADDR, 1'b1}, ack);  // Address + Read
        check_ack("T3 read addr ACK", 1, ack);
        i2c_read_byte(0, read_data);               // NACK（只讀 1 byte）
        i2c_stop;
        #(I2C_PERIOD);
        check("T3 read data", 8'hA5, read_data);

        //----------------------------------------------------------------------
        // Test 4: Multi-byte read — 連續讀 reg[0x02]=0x11, reg[0x03]=0x22
        //----------------------------------------------------------------------
        $display("\n=== Test 4: Multi-byte read (auto-increment) ===");
        // 設定 register pointer 到 0x02
        i2c_start;
        i2c_write_byte({SLAVE_ADDR, 1'b0}, ack);
        check_ack("T4 write addr ACK", 1, ack);
        i2c_write_byte(8'h02, ack);
        check_ack("T4 reg_addr ACK", 1, ack);
        i2c_stop;
        #(I2C_PERIOD);
        // 連續讀 2 bytes
        i2c_start;
        i2c_write_byte({SLAVE_ADDR, 1'b1}, ack);
        check_ack("T4 read addr ACK", 1, ack);
        i2c_read_byte(1, read_data);               // ACK（還要繼續讀）
        check("T4 read data1", 8'h11, read_data);
        i2c_read_byte(0, read_data);               // NACK（最後一個 byte）
        check("T4 read data2", 8'h22, read_data);
        i2c_stop;
        #(I2C_PERIOD);

        //----------------------------------------------------------------------
        // Test 5: Write + Repeated Start + Read
        // 寫 0xBE 到 reg[0x05]，再用 repeated start 讀回來
        //----------------------------------------------------------------------
        $display("\n=== Test 5: Write + Repeated Start + Read ===");
        // 先寫入資料
        i2c_start;
        i2c_write_byte({SLAVE_ADDR, 1'b0}, ack);
        check_ack("T5 write addr ACK", 1, ack);
        i2c_write_byte(8'h05, ack);                // Register address = 0x05
        check_ack("T5 reg_addr ACK", 1, ack);
        i2c_write_byte(8'hBE, ack);                // Data = 0xBE
        check_ack("T5 data ACK", 1, ack);
        i2c_stop;
        #(I2C_PERIOD);
        check("T5 reg[0x05] after write", 8'hBE, uut.register_file[5]);

        // 用 repeated start 讀回
        i2c_start;
        i2c_write_byte({SLAVE_ADDR, 1'b0}, ack);
        check_ack("T5 write addr2 ACK", 1, ack);
        i2c_write_byte(8'h05, ack);                // 設定 reg pointer = 0x05
        check_ack("T5 reg_addr2 ACK", 1, ack);
        i2c_start;                                  // Repeated START（不送 STOP）
        i2c_write_byte({SLAVE_ADDR, 1'b1}, ack);  // Address + Read
        check_ack("T5 read addr ACK", 1, ack);
        i2c_read_byte(0, read_data);               // NACK
        i2c_stop;
        #(I2C_PERIOD);
        check("T5 read back", 8'hBE, read_data);

        //----------------------------------------------------------------------
        // Test 6: Address mismatch — slave 不應回 ACK
        //----------------------------------------------------------------------
        $display("\n=== Test 6: Address mismatch ===");
        i2c_start;
        i2c_write_byte({WRONG_ADDR, 1'b0}, ack);
        check_ack("T6 wrong addr NACK", 0, ack);  // 期望沒有 ACK
        i2c_stop;
        #(I2C_PERIOD);

        //----------------------------------------------------------------------
        // 結果總結
        //----------------------------------------------------------------------
        $display("\n========================================");
        $display("  Results: %0d passed, %0d failed", pass_count, fail_count);
        $display("========================================\n");
        $finish;
    end

    // Timeout 防呆
    initial begin
        #1_000_000;
        $display("[TIMEOUT] Simulation exceeded time limit");
        $finish;
    end

endmodule
