# I2C Master/Slave Controller (SystemVerilog)

SystemVerilog 重寫的 I2C controller，改善架構並加入進階功能。

## 與 .v 版本的差異

- **Two-tier FSM**：Transaction FSM + Physical FSM 分離，cmd 信號溝通
- **Clock stretching**：master 讀回 `i_scl` 確認 SCL 狀態
- **Arbitration loss**：master 讀回 `i_sda` 偵測匯流排衝突
- **Open-drain 介面**：`oe` + `input` 取代 `inout`，貼近實務設計
- **cocotb UVM-like 驗證框架**：driver / monitor / scoreboard / reference model

## Build & Run

需要 [Icarus Verilog](https://github.com/steveicarus/iverilog) 和 [cocotb](https://www.cocotb.org/)。

```bash
# 執行 clk_div smoke test
cd tests
python test_i2c_clk_div_smoke.py
```

## 目錄結構

```
rtl/            SystemVerilog 設計檔
tb/             Testbench top（供 cocotb 接線）
verification/   cocotb UVM-like 驗證元件
tests/          cocotb 測試案例
waves/          波形輸出
```

詳細規劃見 [plan.md](plan.md)。
