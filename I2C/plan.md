# I2C Implementation Plan (5 Days)

> 目標：完整實作 I2C Master + Slave，打造可展示的作品集
> 工具：iverilog + vvp (compile & simulate), gtkwave (waveform)

---

## Day 1: I2C Master - Single Byte Write

**目標：最核心的 FSM，展示重點**

### 產出檔案
- `i2c_master.v` — Master controller
- `i2c_master_tb.v` — Testbench (含 behavioral slave model)

### 實作內容
- [ ] Master FSM：`IDLE → START → ADDR[7:1] → R/W → ACK_CHECK → DATA[7:0] → ACK_CHECK → STOP`
- [ ] SCL clock generation（clock divider from system clock）
- [ ] SDA open-drain tri-state 建模（`assign sda = sda_oe ? sda_out : 1'bz`）
- [ ] Shift register for bit-banging（MSB first）
- [ ] Testbench：pullup model + simple slave behavioral response，驗證 write transaction

### 展示重點
- Start/Stop condition 的時序（SDA edge while SCL HIGH）
- 為什麼 SDA 要 open-drain（multi-master arbitration、wired-AND）
- Setup/hold time on SDA vs SCL

---

## Day 2: I2C Master - Read + Repeated Start

**目標：完整 Master 功能**

### 產出檔案
- 擴充 `i2c_master.v`
- 更新 `i2c_master_tb.v`

### 實作內容
- [ ] Read transaction：Master 在 data phase 釋放 SDA，從 slave 讀取
- [ ] Master ACK/NACK：讀最後一個 byte 送 NACK 通知 slave 結束
- [ ] Repeated Start：不送 STOP 直接送新 START（用於 register read）
- [ ] Multi-byte 支援：byte counter + done signal，連續 N-byte read/write
- [ ] Testbench：驗證 register read pattern（write addr → repeated start → read data）

### 展示重點
- Read vs Write 時 SDA ownership 切換
- Repeated Start 用途：避免釋放 bus，常用於 sensor register read
- 為什麼最後一個 byte 要 NACK

---

## Day 3: I2C Slave Controller

**目標：從另一端理解協議，展示完整掌握**

### 產出檔案
- `i2c_slave.v` — Slave controller with register file
- `i2c_slave_tb.v` — Testbench (含 behavioral master model)

### 實作內容
- [ ] Start/Stop condition detection（SDA falling/rising edge while SCL HIGH）
- [ ] Address match：7-bit address 比對，決定是否 ACK
- [ ] Slave FSM：`IDLE → ADDR_RECV → ACK_ADDR → DATA_RECV/SEND → ACK_DATA → ...`
- [ ] 內建 register file：8 個 8-bit registers，支援 random read/write
- [ ] Write path：第一個 data byte = register address，後續 byte = data（auto-increment）
- [ ] Read path：從 register address 讀出 data，送到 SDA

### 展示重點
- Start/Stop detection 實作（negedge/posedge SDA sampled when SCL HIGH）
- Slave 用 SCL 的 edge 做 sampling，不需自己產 clock
- Clock domain 問題：system clock vs SCL

---

## Day 4: System Integration + Verification

**目標：Master + Slave 接在同一條 bus 上完整跑通**

### 產出檔案
- `i2c_top.v` — Top-level：Master + Slave + bus model
- `i2c_system_tb.v` — Full system testbench

### 實作內容
- [ ] Open-drain bus model：`wire sda; assign sda = (master_sda_oe ? 1'b0 : 1'bz) & (slave_sda_oe ? 1'b0 : 1'bz);` + pullup
- [ ] 完整 transaction 測試：
  - Single byte write → read back → compare
  - Multi-byte write → read back → compare
  - Repeated start register read
- [ ] Self-checking testbench：自動比對 write data vs read data
- [ ] Protocol checker / assertion：
  - Start/Stop condition 時序合法
  - SDA 只在 SCL LOW 時切換（data phase）
  - Bus idle detection

### 展示重點
- Bus contention / tri-state modeling in Verilog
- 如何 debug serial protocol（waveform 分析）
- Testbench architecture：self-checking vs manual inspection

---

## Day 5: Edge Cases + Demo Prep

**目標：展示深度理解，拉開差距**

### 產出檔案
- 擴充所有現有模組
- `README.md`（可選）

### 實作內容
- [ ] Clock stretching：Slave 拉低 SCL 暫停傳輸，Master 偵測並等待
- [ ] NACK handling：
  - Address NACK → Master abort + STOP
  - Data NACK → 停止傳送
- [ ] Bus error recovery：timeout detection（SCL stuck low）
- [ ] Parameterize：clock divider ratio、slave address 可配置
- [ ] 畫 state diagram（手繪即可，展示講解用）
- [ ] 整理 waveform screenshot（start/stop/read/write 各一張）

### Demo 練習
- [ ] 徒手畫 I2C write transaction timing diagram
- [ ] 徒手畫 I2C read transaction timing diagram（含 repeated start）
- [ ] 口頭解釋每個 FSM state 的作用
- [ ] 解釋 open-drain 電路原理

---

## Extra: cocotb + FastAPI 互動式測試平台（作品集）

> 完成 Day 1–5 基本實作後的進階延伸，打造可展示的作品集項目
> 目標：用 Python 生態系包裝 Verilog 設計，提供 Web UI 操控 I2C Master/Slave 模擬

### 為什麼做這個

- 展示亮點：不只寫 RTL，還能搭建完整驗證環境
- 證明跨領域能力：Verilog + Python + Web，符合現代 verification 趨勢
- cocotb 是業界逐漸採用的驗證框架，熟悉度加分

### 架構概覽

```
Browser (React/簡易 HTML)
    ↕ HTTP / WebSocket
FastAPI Server (Python)
    ↕ cocotb API
cocotb Testbench
    ↕ VPI
Icarus Verilog Simulation (i2c_top.v)
```

### 產出檔案

```
I2C/
├── ...（既有 Verilog 檔案）
├── cocotb_tests/
│   ├── requirements.txt        — cocotb, fastapi, uvicorn, websockets
│   ├── Makefile                 — cocotb simulation makefile
│   ├── test_i2c_master.py      — cocotb 基本測試
│   ├── test_i2c_slave.py       — cocotb 基本測試
│   ├── test_i2c_system.py      — 整合測試
│   └── i2c_driver.py           — cocotb driver/monitor class（可重用）
├── server/
│   ├── app.py                  — FastAPI 主程式
│   ├── sim_manager.py          — 管理 cocotb simulation 生命週期
│   └── models.py               — Pydantic request/response models
└── frontend/
    └── index.html              — 簡易前端（或用 FastAPI 內建 Jinja2）
```

### Phase 1: cocotb 測試遷移

- [ ] 安裝 cocotb 環境，確認可與 iverilog 搭配運行
- [ ] 將 Day 4 的 self-checking testbench 改寫為 cocotb Python 測試
- [ ] 建立 `I2CDriver` class：封裝 write/read transaction 的 coroutine
- [ ] 建立 `I2CMonitor` class：監聽 bus 並解碼 transaction 記錄
- [ ] 用 `pytest` 風格組織測試案例，跑通 single byte write/read

### Phase 2: FastAPI 後端

- [ ] 建立 FastAPI server，提供 REST API：
  - `POST /api/write` — 觸發 I2C write transaction（參數：slave addr, reg addr, data）
  - `POST /api/read` — 觸發 I2C read transaction（參數：slave addr, reg addr, byte count）
  - `GET /api/registers` — 讀取 slave register file 當前狀態
  - `GET /api/status` — 模擬狀態（running/idle/error）
- [ ] 用 WebSocket 推送即時 bus activity（每個 bit transition 事件）
- [ ] `sim_manager.py`：管理模擬 process 的啟動/停止/重置

### Phase 3: 前端互動介面

- [ ] 簡易 Web UI（單頁 HTML + vanilla JS 或輕量框架）：
  - I2C Write 表單：輸入 slave address、register、data → 送出後顯示結果
  - I2C Read 表單：輸入 slave address、register → 顯示讀回的值
  - Register File 可視化：8 個 register 的即時狀態表格
  - Bus Activity Log：WebSocket 即時顯示 SDA/SCL 變化（類似 logic analyzer）
- [ ] 波形簡易視覺化：用 canvas 或 SVG 畫出最近 N 個 clock cycle 的 SDA/SCL

### Phase 4: 進階功能（optional）

- [ ] Error injection：前端按鈕觸發 NACK、bus stuck、clock stretching 等異常情境
- [ ] Multi-transaction script：上傳一組 transaction sequence（JSON），批次執行並回報結果
- [ ] 波形匯出：產生 VCD 片段供下載，可用 Surfer 開啟
- [ ] Docker 打包：`docker-compose up` 一鍵啟動整個 demo

### Demo 展示重點

- 現場 demo：打開瀏覽器，即時操控 I2C bus，展示 write → read back → register 狀態更新
- 講解 cocotb 如何透過 VPI 跟 simulator 溝通
- 說明為什麼用 Python 做驗證（靈活性、ecosystem、coverage 分析）
- 展示 error injection 後的 bus recovery 行為

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
├── waveforms/              (optional, gtkwave screenshots)
├── cocotb_tests/           (Extra: cocotb 測試)
│   ├── requirements.txt
│   ├── Makefile
│   ├── i2c_driver.py
│   ├── test_i2c_master.py
│   ├── test_i2c_slave.py
│   └── test_i2c_system.py
├── server/                 (Extra: FastAPI 後端)
│   ├── app.py
│   ├── sim_manager.py
│   └── models.py
└── frontend/               (Extra: 互動前端)
    └── index.html
```
