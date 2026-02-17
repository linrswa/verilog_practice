# Edge Detector（邊緣偵測器）

## 目標
實作一個可偵測輸入信號 rising edge 和 falling edge 的模組，為 I2C Start/Stop condition detection 做準備。

## Module Interface

```verilog
module edge_detector (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       sig_in,      // 要偵測邊緣的輸入信號
    output wire       rising_edge,  // 偵測到上升沿時為 1（維持一個 clk cycle）
    output wire       falling_edge  // 偵測到下降沿時為 1（維持一個 clk cycle）
);
```

## 行為規格
- [ ] 用 `clk` 的 posedge 對 `sig_in` 取樣，記住「前一個 cycle 的值」
- [ ] `rising_edge`：前一個 cycle 為 0，這個 cycle 為 1 → 輸出一個 cycle 的 pulse
- [ ] `falling_edge`：前一個 cycle 為 1，這個 cycle 為 0 → 輸出一個 cycle 的 pulse
- [ ] Reset 時，所有暫存器歸零，edge output 為 0
- [ ] `rising_edge` 和 `falling_edge` 都只維持 **一個 clock cycle**（pulse, 不是 level）

## 測試要點（Testbench 需驗證）
- [ ] `sig_in` 從 0 → 1：`rising_edge` 出現一個 cycle pulse
- [ ] `sig_in` 從 1 → 0：`falling_edge` 出現一個 cycle pulse
- [ ] `sig_in` 保持不變時：兩個 output 都為 0
- [ ] Reset 期間：output 為 0
- [ ] 連續快速切換 `sig_in`：每次切換都正確偵測

## I2C 應用情境

完成基本 edge detector 後，思考以下問題：

> I2C 的 Start condition 是「SCL 為 HIGH 時，SDA 出現 falling edge」。
> 如果你有一個 `edge_detector` 偵測 SDA，你要怎麼加上「SCL 為 HIGH」這個條件？

這不需要寫 code，但想通這個問題會幫助你理解 Day 3 Slave 的 Start/Stop detection。

## 提示
- 核心概念：你只需要 **一個 reg** 來記住前一個 cycle 的值
- `rising_edge` 和 `falling_edge` 可以用 combinational logic（`assign`）產生，不需要額外的 reg
- 想想 `sig_in` 和 `sig_in_prev` 的四種組合（00, 01, 10, 11），哪些對應 rising/falling？

## 編譯與執行

```bash
iverilog -o out/edge_detector edge_detector.v edge_detector_tb.v
vvp out/edge_detector
```
