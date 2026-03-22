# I2C Master/Slave Controller（Verilog）

從零開始實作的 I2C master + slave 控制器，涵蓋 single/multi-byte read/write、repeated start、open-drain bus 整合。

## 進度總覽

| Phase | 項目 | 狀態 |
|-------|------|------|
| 3 | Master single-byte write | ✅ 完成 |
| 4 | Master read + repeated start + multi-byte | ✅ 完成 |
| 5 | Slave controller + register file | ✅ 完成 |
| 6 | 系統整合（master + slave） | ✅ 完成（3 bugs fixed） |
| 6 | Slave Bug 4（READ-ACK false STOP） | ❌ 待修 |
| 7 | Clock stretching / bus error recovery | ❌ 未開始 |
| 8 | cocotb + FastAPI 互動平台 | 🔧 基礎 cocotb 測試已建立 |

## 設計架構

### Master（`i2c_master.v`）
- **FSM**：IDLE → START → ADDR → WRITE/READ → ACK → STOP / REPEATED_START
- SCL 由 clock divider 產生（4-phase：N_EDGE / LOW_MID / P_EDGE / HIGH_MID）
- 支援 multi-byte read/write（`num_bytes` 參數）
- Open-drain 介面：`sda_oe` / `scl_oe` 控制線
- `done`、`data_valid` 為 one-cycle pulse 輸出

### Slave（`i2c_slave.v`）
- 8×8-bit register file，支援 read/write
- 7-bit address matching
- Write：第一 byte = register address，後續 byte = data（auto-increment）
- Read：從 current register address 開始串流
- START / STOP condition 偵測

### System（`i2c_top.v`）
- Master + Slave 透過 wired-AND open-drain bus 連接
- 含 pullup resistor 模型

## 檔案結構

```
I2C/
├── i2c_master.v          # Master 控制器
├── i2c_slave.v           # Slave 控制器 + register file
├── i2c_top.v             # 系統整合頂層
├── i2c_master_tb.v       # Master standalone testbench
├── i2c_slave_tb.v        # Slave standalone testbench
├── i2c_system_tb.v       # End-to-end 整合測試
├── cocotb/
│   ├── test_i2c_master.py    # cocotb master 測試
│   ├── test_i2c_slave.py     # cocotb slave 測試
│   ├── test_i2c_system.py    # cocotb 系統測試
│   ├── i2c_test.py           # Python runner（支援 master/slave/system target）
│   ├── i2c_master_wrapper.v  # cocotb master wrapper
│   ├── i2c_slave_wrapper.v   # cocotb slave wrapper
│   └── i2c_system_wrapper.v  # cocotb system wrapper
└── fix_log.md            # Bug 修正紀錄（4 bugs documented）
```

## 編譯與模擬

```bash
# Verilog testbench
iverilog -o out/i2c_system i2c_top.v i2c_master.v i2c_slave.v i2c_system_tb.v
vvp out/i2c_system

# cocotb（需安裝 cocotb）
cd cocotb
python i2c_test.py --target system
```

## Bug 修正紀錄

階段 6 整合測試發現 4 個 bug，其中 3 個已修正。詳見 [fix_log.md](fix_log.md)。

| Bug | 描述 | 狀態 |
|-----|------|------|
| #1 | WRITE state SDA 過早釋放 → 假 STOP | ✅ Fixed |
| #2 | `data_valid` 未清除（非 one-cycle pulse） | ✅ Fixed |
| #3 | STOP state SCL 不 clock → slave 無法釋放 ACK | ✅ Fixed |
| #4 | Slave READ-ACK 階段誤判 STOP | ❌ Pending |

> Bug #1、#3 僅在接上 real slave 時觸發，standalone testbench 無法偵測。這是整合測試的價值所在。

## 學到的教訓

- **Standalone testbench 的盲點**：behavioral slave task 不會偵測 STOP condition，導致 Bug #1、#3 在單元測試中隱形
- **One-cycle pulse 紀律**：所有旗標信號（`done`、`data_valid`）必須在 always block 頂層清除
- **Open-drain 時序**：SDA 只能在 SCL LOW 時變化，否則會產生 START/STOP condition
