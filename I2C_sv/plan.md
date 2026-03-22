## 設計決策

### 架構選擇（經研究確認）
- **Two-tier FSM**：Transaction FSM（管流程）+ Physical FSM（管線路時序），透過 cmd 信號溝通
- **不使用共用 byte_ctrl**：master/slave 時序驅動模式根本不同（master: phase-based, slave: edge-reactive），byte 邏輯各自內嵌
- **Physical FSM 多步驟用拆 state**：START/STOP 的子步驟拆成獨立 state（業界標準），重複動作（shift 8 bits）用 counter
- **Open-drain 介面**：`scl_oe` + `i_scl` / `sda_oe` + `i_sda`，不用 `inout`，支援 clock stretching

### 相較 .v 版本的改進
| | I2C/（.v 版本） | I2C_sv/（本專案） |
|---|---|---|
| 結構 | 單一 FSM | Two-tier FSM，module 拆分 |
| Clock stretching | 無 | 有（讀回 i_scl） |
| Arbitration loss | 無 | 有（讀回 i_sda） |
| Bus 介面 | `inout sda` | `oe` + `input` |
| Setup/Hold time | 被 CLK_DIV 綁死 | 可獨立調整（未來） |
| 驗證 | 基本 testbench | cocotb UVM-like 框架 |
| 語言 | Verilog | SystemVerilog |

---

## structure

```
I2C_sv/
├─ rtl/
│  ├─ i2c_pkg.sv          # 共用型別、常數（i2c_rw_e, i2c_ack_e）
│  ├─ i2c_clk_div.sv      # SCL 時鐘分頻（4-phase: FALLING/LOW_MID/RISING/HIGH_MID）
│  ├─ i2c_master.sv       # master 控制器（two-tier FSM，byte 邏輯內嵌）
│  ├─ i2c_slave_mem.sv    # slave 控制器 + EEPROM memory（byte 邏輯內嵌）
│  └─ i2c_top.sv          # master + slave 頂層連接 + open-drain 組合
│
├─ tb/
│  └─ tb_top.sv           # DUT 實例化 + cocotb 接線
│
├─ verification/
│  ├─ __init__.py
│  ├─ bus.py              # I2C 信號層操作（start/stop/bit 驅動）
│  ├─ driver.py           # 發送 transaction（write/read sequence）
│  ├─ monitor.py          # 監聽匯流排、解析 transaction
│  ├─ model.py            # reference model（預期行為）
│  ├─ scoreboard.py       # 比對 monitor 結果 vs model 預期
│  └─ env.py              # 組裝 driver/monitor/scoreboard
│
├─ tests/
│  ├─ test_smoke.py
│  ├─ test_write.py
│  ├─ test_read.py
│  ├─ test_repeated_start.py
│  ├─ test_clock_stretch.py
│  ├─ test_arbitration.py
│  └─ test_multi_byte.py
│
├─ waves/                  # 波形輸出
├─ plan.md
└─ README.md
```

---

## plan

### Phase 1: master RTL + smoke test ← 目前進度
- [x] i2c_pkg.sv（共用常數、i2c_rw_e、i2c_ack_e）
- [x] i2c_clk_div.sv（SCL 產生 + cocotb smoke test）
- [ ] i2c_master.sv
    - Two-tier FSM（Transaction FSM + Physical FSM）
    - Transaction FSM：MST_IDLE → MST_START → MST_ADDR → MST_DATA → MST_STOP
    - Physical FSM：START/STOP 拆 state，WRITE/READ 用 bit_cnt counter
    - single-byte read/write
    - multi-byte read/write
    - ack/nack handling
    - repeated start
    - clock stretching（等 i_scl 確認 SCL 真的 high）
    - arbitration loss（檢查 i_sda 是否與預期一致）
- [ ] cocotb smoke test（驗證 master 基本波形）

### Phase 2: slave RTL + smoke test
- [ ] i2c_slave_mem.sv
    - 自己的 FSM + byte 邏輯（edge-reactive，偵測 SCL 邊緣）
    - address match + read/write
    - ack/nack handling
    - 內建 EEPROM memory
    - clock stretching（slave 主動拉住 SCL）
- [ ] cocotb smoke test（驗證 slave 回應）

### Phase 3: top 整合
- [ ] i2c_top.sv（master ↔ slave 連接 + open-drain wired-AND）
- [ ] tb_top.sv（DUT 實例化，供 cocotb 驅動）
- [ ] 整合 smoke test

### Phase 4: cocotb UVM-like 驗證框架
- [ ] bus / driver / monitor / model / scoreboard / env
- [ ] 完整測試：
    - write（single + multi-byte）
    - read（single + multi-byte）
    - repeated start
    - clock stretching（slave 拉住 SCL）
    - arbitration loss（master 偵測到 SDA 衝突）
    - NACK handling（slave 無回應）
