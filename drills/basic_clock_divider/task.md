# 基礎練習：Clock Divider

## 目標
實作一個最基本的 clock divider，用 counter 把輸入時脈除頻。不涉及任何協定，純粹練習「計數器翻轉輸出」的概念。

## Module Interface

```verilog
module clock_divider (
    input  wire clk,      // 輸入時脈
    input  wire rst_n,    // 非同步 reset（active low）
    output reg  clk_out   // 除頻後的輸出時脈
);
```

## Parameter

| Parameter | 說明 | 預設值 |
|-----------|------|--------|
| DIV       | 除頻倍數（偶數） | 4 |

> 例如 DIV=4 代表輸出頻率 = 輸入頻率 / 4

## 行為規格
- [ ] `rst_n` 為 LOW 時，`clk_out` 輸出 0，counter 歸零（非同步 reset，不等 clk）
- [ ] 正常運作時，counter 在每個 `posedge clk` 加 1
- [ ] counter 數到 `DIV/2 - 1` 時，翻轉 `clk_out` 並將 counter 歸零
- [ ] 輸出的 duty cycle 為 50%

## 測試要點
- 用 DIV=4 觀察波形，確認輸出頻率是輸入的 1/4
- 用 DIV=2 測試最小除頻（每個 clk 正緣翻轉一次）
- 測試 reset：在運作中途拉低 `rst_n`，確認 `clk_out` 立刻歸 0、counter 歸零
- reset 釋放後，確認能正常重新開始計數

## 提示
- 你需要一個 counter 暫存器，想想它需要幾個 bit 寬？（跟 DIV 的大小有關）
- `always @(posedge clk or negedge rst_n)` — 想想為什麼 reset 用 `negedge`
- 翻轉 `clk_out` 可以用 `~clk_out` 或 `!clk_out`
