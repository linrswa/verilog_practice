# I2C 學習與實作計畫

> 目標：從基礎元件開始，逐步建構完整 I2C Master + Slave，打造可展示的作品集
> 工具：iverilog + vvp (compile & simulate), Surfer (waveform)

---

## 階段 1：數位基礎元件

- [x] **DFF with async reset** — `FF/ff.v` + testbench
- [x] **Vending machine FSM** — `FSM/vending_fsm.v` + self-checking testbench（Mealy-style, 6 test cases）

---

## 階段 2：I2C 暖身練習（Drills）

- [x] **Basic clock divider** — `drills/basic_clock_divider/`（counter-based, DIV=4, 50% duty cycle）
- [x] **Tri-state bus modeling** — `drills/tri_state_bus/`（open-drain output + wired-AND bus testbench）
- [x] **Edge detector** — `drills/edge_detector/`（rising/falling edge 單 cycle pulse，用於 Start/Stop detection）
- [x] **I2C warmup: clock divider** — `drills/i2c_warmup_clock_divider/`（含 enable、SCL mid-point pulse）
- [ ] **I2C warmup: shift register** — `drills/i2c_warmup_shift_register/`（8-bit PISO, MSB-first, done flag）

---

## 階段 3：I2C Master — Single Byte Write

> 產出：`i2c_master.v` + `i2c_master_tb.v`

- [ ] Master FSM：`IDLE → START → ADDR[7:1] → R/W → ACK_CHECK → DATA[7:0] → ACK_CHECK → STOP`
- [ ] SCL clock generation（clock divider from system clock）
- [ ] SDA open-drain tri-state 建模（`assign sda = sda_oe ? sda_out : 1'bz`）
- [ ] Shift register for bit-banging（MSB first）
- [ ] Testbench：pullup model + simple slave behavioral response，驗證 write transaction

**展示重點：** Start/Stop condition 時序、open-drain 原理、Setup/hold time on SDA vs SCL

---

## 階段 4：I2C Master — Read + Repeated Start

> 產出：擴充 `i2c_master.v` + 更新 `i2c_master_tb.v`

- [ ] Read transaction：Master 在 data phase 釋放 SDA，從 slave 讀取
- [ ] Master ACK/NACK：讀最後一個 byte 送 NACK 通知 slave 結束
- [ ] Repeated Start：不送 STOP 直接送新 START（用於 register read）
- [ ] Multi-byte 支援：byte counter + done signal，連續 N-byte read/write
- [ ] Testbench：驗證 register read pattern（write addr → repeated start → read data）

**展示重點：** SDA ownership 切換、Repeated Start 用途、為什麼最後一個 byte 要 NACK

---

## 階段 5：I2C Slave Controller

> 產出：`i2c_slave.v` + `i2c_slave_tb.v`

- [ ] Start/Stop condition detection（SDA falling/rising edge while SCL HIGH）
- [ ] Address match：7-bit address 比對，決定是否 ACK
- [ ] Slave FSM：`IDLE → ADDR_RECV → ACK_ADDR → DATA_RECV/SEND → ACK_DATA → ...`
- [ ] 內建 register file：8 個 8-bit registers，支援 random read/write
- [ ] Write path：第一個 data byte = register address，後續 byte = data（auto-increment）
- [ ] Read path：從 register address 讀出 data，送到 SDA

**展示重點：** Start/Stop detection 實作、Slave 用 SCL edge sampling、system clock vs SCL clock domain

---

## 階段 6：系統整合 + 驗證

> 產出：`i2c_top.v` + `i2c_system_tb.v`

- [ ] Open-drain bus model（master + slave 共用 SDA/SCL + pullup）
- [ ] 完整 transaction 測試：single byte write/read back、multi-byte、repeated start register read
- [ ] Self-checking testbench：自動比對 write data vs read data
- [ ] Protocol checker / assertion：Start/Stop 時序合法、SDA 只在 SCL LOW 切換、bus idle detection

**展示重點：** Bus contention / tri-state modeling、serial protocol debug、self-checking testbench architecture

---

## 階段 7：Edge Cases + Demo 準備

- [ ] Clock stretching：Slave 拉低 SCL 暫停傳輸，Master 偵測並等待
- [ ] NACK handling：Address NACK → abort + STOP、Data NACK → 停止傳送
- [ ] Bus error recovery：timeout detection（SCL stuck low）
- [ ] Parameterize：clock divider ratio、slave address 可配置
- [ ] 畫 state diagram（展示講解用）
- [ ] 整理 waveform screenshot（start/stop/read/write 各一張）

### Demo 練習

- [ ] 徒手畫 I2C write transaction timing diagram
- [ ] 徒手畫 I2C read transaction timing diagram（含 repeated start）
- [ ] 口頭解釋每個 FSM state 的作用
- [ ] 解釋 open-drain 電路原理

---

## 階段 8（Extra）：cocotb + FastAPI 互動式測試平台

> 進階延伸，用 Python 生態系包裝 Verilog 設計，提供 Web UI 操控 I2C 模擬
> 展示亮點：RTL + 完整驗證環境 + 跨領域能力（Verilog + Python + Web）

```
Browser (React/簡易 HTML)
    ↕ HTTP / WebSocket
FastAPI Server (Python)
    ↕ cocotb API
cocotb Testbench
    ↕ VPI
Icarus Verilog Simulation (i2c_top.v)
```

### Phase 1: cocotb 測試遷移

- [ ] 安裝 cocotb 環境，確認可與 iverilog 搭配運行
- [ ] 將 self-checking testbench 改寫為 cocotb Python 測試
- [ ] 建立 `I2CDriver` class：封裝 write/read transaction 的 coroutine
- [ ] 建立 `I2CMonitor` class：監聽 bus 並解碼 transaction 記錄
- [ ] 用 `pytest` 風格組織測試案例，跑通 single byte write/read

### Phase 2: FastAPI 後端

- [ ] 建立 FastAPI server（REST API: write/read/registers/status）
- [ ] 用 WebSocket 推送即時 bus activity（每個 bit transition 事件）
- [ ] `sim_manager.py`：管理模擬 process 的啟動/停止/重置

### Phase 3: 前端互動介面

- [ ] 簡易 Web UI：I2C Write/Read 表單、Register File 可視化、Bus Activity Log
- [ ] 波形簡易視覺化：用 canvas 或 SVG 畫出最近 N 個 clock cycle 的 SDA/SCL

### Phase 4: 進階功能（optional）

- [ ] Error injection：前端按鈕觸發 NACK、bus stuck、clock stretching 等異常情境
- [ ] Multi-transaction script：上傳 transaction sequence（JSON），批次執行
- [ ] 波形匯出：產生 VCD 片段供下載
- [ ] Docker 打包：`docker-compose up` 一鍵啟動

---

## 常見 I2C 問題

| 問題 | 關鍵答案 |
|------|----------|
| 為什麼 SDA 是 open-drain？ | 多 master 仲裁（wired-AND），任一裝置拉低即為 LOW |
| Start/Stop condition？ | SDA ↓ while SCL HIGH = Start；SDA ↑ while SCL HIGH = Stop |
| Clock stretching？ | Slave holds SCL LOW，Master 必須等 SCL 釋放才繼續 |
| Multi-master arbitration？ | 每個 master 監控 SDA，發 1 但讀到 0 表示輸了，退出 |
| I2C vs SPI？ | I2C：2 wire, addressed, multi-master, slower；SPI：4+ wire, CS-based, faster, full-duplex |
| ACK vs NACK？ | Receiver 拉低 SDA = ACK；不拉 = NACK（SDA stays HIGH） |
| 10-bit addressing？ | 前 5 bit = 11110，接 2-bit addr，再一個 byte 補 8-bit addr |

---

## 專案結構（完成後）

```
I2C/
├── plan.md
├── i2c_master.v
├── i2c_slave.v
├── i2c_top.v
├── i2c_master_tb.v
├── i2c_slave_tb.v
├── i2c_system_tb.v
├── waveforms/
├── cocotb_tests/
│   ├── requirements.txt
│   ├── Makefile
│   ├── i2c_driver.py
│   ├── test_i2c_master.py
│   ├── test_i2c_slave.py
│   └── test_i2c_system.py
├── server/
│   ├── app.py
│   ├── sim_manager.py
│   └── models.py
└── frontend/
    └── index.html
```
