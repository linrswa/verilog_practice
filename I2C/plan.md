# I2C Implementation Plan (5 Days)

> 目標：完整實作 I2C Master + Slave，準備 1-2 週後的 interview
> 工具：iverilog + vvp (compile & simulate), gtkwave (waveform)

---

## Day 1: I2C Master - Single Byte Write

**目標：最核心的 FSM，面試必問**

### 產出檔案
- `i2c_master.v` — Master controller
- `i2c_master_tb.v` — Testbench (含 behavioral slave model)

### 實作內容
- [ ] Master FSM：`IDLE → START → ADDR[7:1] → R/W → ACK_CHECK → DATA[7:0] → ACK_CHECK → STOP`
- [ ] SCL clock generation（clock divider from system clock）
- [ ] SDA open-drain tri-state 建模（`assign sda = sda_oe ? sda_out : 1'bz`）
- [ ] Shift register for bit-banging（MSB first）
- [ ] Testbench：pullup model + simple slave behavioral response，驗證 write transaction

### 面試考點
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

### 面試考點
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

### 面試考點
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

### 面試考點
- Bus contention / tri-state modeling in Verilog
- 如何 debug serial protocol（waveform 分析）
- Testbench architecture：self-checking vs manual inspection

---

## Day 5: Edge Cases + Interview Prep

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
- [ ] 畫 state diagram（手繪即可，面試講解用）
- [ ] 整理 waveform screenshot（start/stop/read/write 各一張）

### Mock Interview 練習
- [ ] 徒手畫 I2C write transaction timing diagram
- [ ] 徒手畫 I2C read transaction timing diagram（含 repeated start）
- [ ] 口頭解釋每個 FSM state 的作用
- [ ] 解釋 open-drain 電路原理

---

## 面試常見 I2C 問題

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
└── waveforms/          (optional, gtkwave screenshots)
```
