# I2C 暖身練習：Clock Divider（SCL 產生器）

## 目標
實作一個可參數化的 clock divider，從高頻系統時鐘產生低頻的 SCL 時鐘。這是 I2C Master 控制 bus 速度的基礎元件。

## Module Interface

```verilog
module clock_divider (
    input  wire clk,        // 系統時鐘（例如 50 MHz）
    input  wire rst_n,      // 非同步 reset（active low）
    input  wire enable,     // 致能信號（LOW 時 SCL 停在 HIGH）
    output reg  scl,        // 產生的 SCL 時鐘
    output wire scl_mid_low,// SCL LOW phase 的中間點（用於切換 SDA）
    output wire scl_mid_high// SCL HIGH phase 的中間點（用於取樣 SDA）
);
```

## Parameter

| Parameter  | 說明                          | 預設值 |
|------------|-------------------------------|--------|
| DIV_COUNT  | SCL half-period 的 clock 數   | 250    |

> 以 50 MHz system clock + DIV_COUNT=250 為例：SCL period = 250×2 = 500 clocks = 100 kHz

## 行為規格
- [ ] `rst_n` 為 LOW 時，`scl` 輸出 HIGH，counter 歸零
- [ ] `enable` 為 LOW 時，`scl` 維持 HIGH，counter 歸零（bus idle 狀態）
- [ ] `enable` 為 HIGH 時，counter 開始計數，每數到 `DIV_COUNT-1` 就翻轉 `scl`
- [ ] `scl_mid_low`：在 SCL LOW phase 的正中間產生一個 single-cycle pulse
- [ ] `scl_mid_high`：在 SCL HIGH phase 的正中間產生一個 single-cycle pulse
- [ ] SCL 的 duty cycle 為 50%（HIGH 和 LOW 等長）

## 測試要點
- 用小的 DIV_COUNT（例如 4）方便觀察波形
- 確認 SCL 頻率是否正確：period = 2 × DIV_COUNT × system clock period
- 確認 `scl_mid_low` 和 `scl_mid_high` 的 pulse 位置正確（在各自 phase 的中間）
- 測試 enable 拉低後 SCL 是否停在 HIGH
- 測試 enable 重新拉高後行為是否正常

## 提示
- Counter 數到 `DIV_COUNT-1` 時歸零並翻轉 SCL，這樣就能得到 50% duty cycle
- `scl_mid_low` 出現在 SCL=0 且 counter=`DIV_COUNT/2-1` 的時候——想想為什麼選中間點
- 在 I2C 中，Master 在 SCL LOW 的中間切換 SDA（確保 setup time），在 SCL HIGH 的中間取樣 SDA（確保資料穩定）。這就是為什麼需要這兩個 mid-point 信號
