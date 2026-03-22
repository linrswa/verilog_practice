# I2C Master/Slave Controller（SystemVerilog）

以 SystemVerilog 重新設計的 I2C controller，改善架構並加入 clock stretching、arbitration loss 偵測等進階功能。

## 進度總覽

| Phase | 項目 | 狀態 |
|-------|------|------|
| 1 | i2c_pkg.sv（共用型別、常數） | ✅ 完成 |
| 1 | i2c_clk_div.sv + smoke test | ✅ 完成 |
| 1 | i2c_master.sv（two-tier FSM） | 🔧 骨架已建立，FSM 邏輯待實作 |
| 1 | cocotb master smoke test | ❌ 未開始 |
| 2 | i2c_slave_mem.sv | ❌ 未開始 |
| 3 | i2c_top.sv 整合 | ❌ 未開始 |
| 4 | cocotb UVM-like 驗證框架 | ❌ 未開始 |

**目前焦點**：Phase 1 — `i2c_master.sv` FSM 實作

## 與 Verilog 版本（`../I2C/`）的差異

| | I2C/（Verilog） | I2C_sv/（SystemVerilog） |
|---|---|---|
| FSM 架構 | 單一 FSM | Two-tier FSM（Transaction + Physical） |
| Clock stretching | 無 | 有（讀回 `i_scl`） |
| Arbitration loss | 無 | 有（讀回 `i_sda`） |
| Bus 介面 | `inout sda` | `oe` + `input`（open-drain） |
| 驗證方式 | Verilog TB + 基礎 cocotb | cocotb UVM-like 框架 |

## 設計架構

### Two-tier FSM
- **Transaction FSM**：管理 I2C 流程（IDLE → START → ADDR → DATA → STOP）
- **Physical FSM**：管理線路時序（START/STOP 拆 state，WRITE/READ 用 bit counter）
- 兩層透過 `cmd` 信號溝通

### Open-drain 介面
- `scl_oe` + `i_scl`：SCL 控制與回讀（支援 clock stretching）
- `sda_oe` + `i_sda`：SDA 控制與回讀（支援 arbitration loss 偵測）

### Clock Divider（`i2c_clk_div.sv`）
- 4-phase 輸出：FALLING → LOW_MID → RISING → HIGH_MID
- 參數化 `DIV` 控制頻率
- 已通過 cocotb smoke test（DIV = 8, 16, 32）

## 檔案結構

```
I2C_sv/
├── rtl/
│   ├── i2c_pkg.sv          # 共用型別（i2c_rw_e, i2c_ack_e）、常數
│   ├── i2c_clk_div.sv      # SCL 時鐘分頻器（4-phase）
│   ├── i2c_master.sv       # Master 控制器（骨架，FSM 待實作）
│   ├── i2c_slave_mem.sv    # [planned] Slave + EEPROM memory
│   └── i2c_top.sv          # [planned] 頂層整合
├── tb/
│   └── tb_top.sv           # [planned] cocotb DUT 接線
├── verification/           # [planned] cocotb UVM-like 元件
│   ├── bus.py              #   信號層操作
│   ├── driver.py           #   transaction 驅動
│   ├── monitor.py          #   匯流排監聽
│   ├── model.py            #   reference model
│   ├── scoreboard.py       #   結果比對
│   └── env.py              #   組裝全部元件
├── tests/
│   └── test_i2c_clk_div_smoke.py  # clk_div smoke test ✅
├── waves/                  # VCD 波形輸出
└── plan.md                 # 詳細規劃與設計決策
```

## 編譯與模擬

使用 Verilator + cocotb：

```bash
# 執行 clk_div smoke test
cd tests
python test_i2c_clk_div_smoke.py
```

## 詳細規劃

見 [plan.md](plan.md)，包含設計決策紀錄與各 phase 的具體項目。
