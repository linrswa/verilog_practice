# Tri-State / Open-Drain Bus 建模

## 目標
理解 `1'bz` 高阻抗狀態與 open-drain bus 的 wired-AND 行為，為 I2C SDA/SCL bus 建模做準備。

## 練習一：Open-Drain Output Module

### Module Interface

```verilog
module open_drain_output (
    input  wire       data_out,   // 想要送出的資料（1 或 0）
    input  wire       output_en,  // 輸出致能：1 = 驅動, 0 = 釋放（高阻抗）
    output wire       pad         // 連接到外部 bus 的 pad（open-drain）
);
```

### 行為規格
- [x] 當 `output_en = 1` 且 `data_out = 0` 時，`pad` 驅動為 `1'b0`（拉低）
- [x] 當 `output_en = 0`，或 `data_out = 1` 時，`pad` 輸出 `1'bz`（釋放 bus）
- [x] 注意：open-drain **只能主動拉低**，不能主動驅動 HIGH — HIGH 由外部 pull-up 電阻提供

### 提示
- 這個模組只需要一行 `assign` 語句
- 想想看：為什麼 open-drain 不能驅動 `1'b1`？如果兩個裝置同時驅動，一個送 1 一個送 0，會發生什麼事？

---

## 練習二：Bus Model with Pull-up

### Module Interface

```verilog
module bus_model_tb;
    wire sda;  // open-drain bus

    // 兩個 device 各自有 output enable 和 data
    reg  device_a_oe;
    reg  device_a_data;
    reg  device_b_oe;
    reg  device_b_data;
```

### 行為規格（Testbench）
- [x] 實例化兩個 `open_drain_output`，共同連接到 `sda` wire
- [x] 模擬 pull-up 電阻：`assign sda = (sda === 1'bz) ? 1'b1 : sda;`
  - 或使用 `pullup(sda);`（iverilog 支援）
- [x] 測試以下情境並用 `$display` 印出 `sda` 的值：

| 情境 | Device A | Device B | 預期 sda |
|------|----------|----------|----------|
| 兩者都釋放 | oe=0 | oe=0 | z |
| A 拉低 | oe=1, data=0 | oe=0 | 0 |
| B 拉低 | oe=0 | oe=1, data=0 | 0 |
| 兩者都拉低 | oe=1, data=0 | oe=1, data=0 | 0 |
| A 釋放 B 拉低 | oe=1, data=1 | oe=1, data=0 | 0 |

- [x] 在表格的 `?` 填入你的預期值，然後跑模擬驗證

### 測試要點
- 觀察 wired-AND 行為：只要有任一裝置拉低，bus 就是 LOW
- 所有裝置都釋放時，pull-up 讓 bus 回到 HIGH
- 這就是 I2C 的 SDA bus 運作原理

### 提示
- pull-up 的模擬有多種寫法，最簡單的是 `pullup(sda);`
- 如果用 `assign` 做 pull-up，注意 `===`（case equality）和 `==` 的差異 — `1'bz == 1'b1` 的結果是什麼？

---

## 編譯與執行

```bash
iverilog -o out/tri_state_bus open_drain_output.v bus_model_tb.v
vvp out/tri_state_bus
```
