# I2C 暖身練習：Shift Register（MSB-first Serial Output）

## 目標
實作一個 8-bit parallel-in, serial-out (PISO) shift register，MSB 先送出。這是 I2C Master 在 SDA 上逐 bit 送出 address/data 的核心機制。

## Module Interface

```verilog
module shift_register_piso (
    input  wire       clk,        // 系統時鐘
    input  wire       rst_n,      // 非同步 reset（active low）
    input  wire       load,       // 載入 parallel data（優先於 shift）
    input  wire       shift_en,   // shift 致能（每個 clock shift 一次）
    input  wire [7:0] data_in,    // 8-bit parallel 輸入
    output wire       serial_out, // 串列輸出（MSB first）
    output wire       done        // 8 個 bit 都送完時拉高
);
```

## 行為規格
- [ ] `rst_n` 為 LOW 時，shift register 清零，bit counter 歸零
- [ ] `load` 為 HIGH 時，將 `data_in` 載入 shift register，bit counter 重置為 0
- [ ] `shift_en` 為 HIGH 且 `load` 為 LOW 時，每個 posedge clk 左移一位，bit counter +1
- [ ] `serial_out` 永遠輸出 shift register 的最高位（MSB）
- [ ] 當 8 個 bit 都已 shift 出去後，`done` 拉高
- [ ] `load` 的優先權高於 `shift_en`（同時為 HIGH 時只做 load）

## 測試要點
- 載入 `8'hA5`（`10100101`），連續 shift 8 次，觀察 serial_out 是否依序為 `1,0,1,0,0,1,0,1`
- 確認 `done` 在第 8 次 shift 後才拉高
- 測試 shift 到一半 re-load 新資料，確認行為正確
- 測試 reset 後的初始狀態

## 提示
- `serial_out` 應該接 shift register 的哪一端？想想「MSB first」的意思
- 左移操作在 Verilog 中可以用 concatenation 實現：`{shift_reg[6:0], 1'b0}`
- Bit counter 可以用一個 3-bit 的 counter（0~7 剛好 8 個值）
