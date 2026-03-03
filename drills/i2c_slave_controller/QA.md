# I2C Slave Controller — QA 複習筆記

## Q1: 時序題 — Start/Stop Condition Detection

**題目：** 在 I2C slave 裡，Start/Stop condition 各是什麼信號條件？如果系統時鐘遠快於 SCL（如 50MHz vs 1MHz），怎麼在 `posedge clk` 的 always block 裡偵測？

**我的回答：** 透過每個 `posedge clk` 持續觀察 `sda_prev`/`scl_prev`（上一個 cycle 的值）和當前 `sda`/`scl`，就能在 SCL HIGH 時抓到 SDA 1→0（Start）和 SDA 0→1（Stop）。

**補充：** 如果 SCL 和 SDA 同時在兩個 posedge clk 之間改變，可能會誤判。Testbench 用 `#205`（5ns offset）避免信號變化剛好落在 clock edge 上，同時 `i2c_start`/`i2c_stop` task 本身用 `#QUARTER`（250ns）隔開 SDA 和 SCL 的變化，確保 slave 能分開偵測。

---

## Q2: Debug 題 — WRITE State Register 損壞

**題目：** 以下 WRITE state 直接把每個 bit shift 進 `register_file[reg_addr]`，為什麼會導致 register 在 STOP 時被損壞？

```verilog
WRITE: begin
    if (scl_rising) begin
        bit_cnt <= bit_cnt + 1;
        if (first_byte_received) begin
            register_file[reg_addr] <= {register_file[reg_addr][6:0], sda};
        end else begin
            reg_addr <= {reg_addr[6:0], sda};
        end
    end
    ...
end
```

**我的回答：** ACK 後 slave 回到 WRITE state（因為不知道 master 接下來要繼續寫還是 STOP）。如果 master 發 STOP，STOP sequence 的 SCL 上升沿會被 WRITE state 當成資料——此時 SDA 是被 master 拉低（準備之後釋放觸發 STOP condition），所以 `register_file[reg_addr]` 被左移一位、LSB 塞入 0，資料被破壞。

**修法：** 用 `shift_reg` 暫存接收中的 byte，收滿 8 bits 後才一次寫入 `register_file`。這樣即使 STOP 的 SCL 上升沿被 sample 到 `shift_reg`，也不會影響 register file。

---

## Q3: 概念題 — 為什麼不用 `posedge scl`？

**題目：** 為什麼 slave 不能直接用 `posedge scl` 觸發邏輯？你的設計怎麼處理？

**我的回答：** SCL 在 idle 時是 HIGH，用 `posedge scl` 會抓不到 start condition（SDA 1→0 while SCL HIGH）。所以用 `posedge clk` 搭配 `scl_prev`/`sda_prev` 持續觀測變化。

**補充（硬體面）：**

1. **Metastability（亞穩態）：** SCL 是外部非同步信號，和系統時鐘完全不同步。FF 在 setup/hold time window 內採樣到正在變化的信號，輸出會進入不確定的中間狀態。真正的 FPGA 設計會用 two-stage synchronizer（兩級 FF）來降低風險。

2. **Clock routing：** FPGA 有專用的低 skew clock network，只有從 clock pin 進來的信號才能走。SCL 從 GPIO 進來，如果當 clock 用只能走一般佈線，clock skew 會大到不可靠。

3. **Clock skew：** 同一個 clock 到達不同 FF 的時間差。如果 skew 太大，下游 FF 可能在上游 FF 輸出還沒穩定時就採樣，導致 setup/hold violation。

**結論：** 業界標準做法是「用快時鐘 oversample 慢信號」。

---

## Q4: 比較題 — 直接寫入 vs Shift Register

**題目：** Write path 兩種方式的 tradeoff：

- **方式 A：** 每個 `scl_rising` 直接 shift 進 `register_file[reg_addr]`
- **方式 B：** 先 shift 進 `shift_reg`，收滿 8 bits 後才寫入 `register_file`

**我的回答：**

- **方式 A 的問題：** ACK 後回到 WRITE，如果 master 送 STOP，STOP 的 SCL 上升沿會把 SDA 值 shift 進 register_file，破壞資料。
- **方式 B 的代價：** 硬體上多 8 個 FF（一個 8-bit shift register），但對 FPGA 來說幾乎可忽略。

**補充：** 方式 B 提供 **atomic write（原子性寫入）**——register file 要嘛完整更新，要嘛完全不動，不會出現「寫到一半」的中間狀態。這是通用設計原則：接收外部資料時，先暫存在 buffer，驗證完整後再 commit。UART、SPI 等 serial protocol 的 receiver 都用同樣的 pattern。

---

## 總結

**掌握好的：** Start/Stop detection、shift_reg 保護機制、bit_cnt 時序

**需加強：** Clock domain crossing / metastability（面試高頻題）——記住 two-stage synchronizer、setup/hold violation、clock skew
