# I2C Master — Read + Repeated Start + Multi-byte

## 目標
在階段三的 single byte write 基礎上，擴充 I2C Master 支援 read transaction、repeated start、以及 multi-byte 連續傳輸。完成後 master 能執行典型的 "register read" 操作：write register address → repeated start → read data back。

## Module Interface

```verilog
module i2c_master (
    input  wire        clk,          // 系統時鐘
    input  wire        rst_n,        // 非同步 reset（active low）

    // Transaction 控制
    input  wire        start,        // 觸發一筆 transaction
    input  wire        rw,           // 0 = write, 1 = read
    input  wire [6:0]  slave_addr,   // 7-bit slave address
    input  wire [7:0]  data_in,      // 寫入用的 data（write mode）
    input  wire [3:0]  num_bytes,    // 本次 transaction 要傳輸的 byte 數（1~15）
    input  wire        repeated_start, // 1 = transaction 結束時送 repeated start 而非 STOP

    // 狀態輸出
    output reg         busy,         // transaction 進行中
    output reg         done,         // transaction 完成（one-cycle pulse）
    output reg         ack_error,    // slave 回 NACK
    output reg  [7:0]  data_out,     // 讀取到的 data（read mode，每 byte 有效時更新）
    output reg         data_valid,   // data_out 有效（one-cycle pulse，每讀完一個 byte 拉高一次）
    output reg  [3:0]  byte_count,   // 目前已傳輸的 byte 數

    // I2C bus
    output wire        scl,          // I2C clock（open-drain）
    inout  wire        sda           // I2C data（open-drain, bidirectional）
);
```

## Parameter

| Parameter | 說明 | 預設值 |
|-----------|------|--------|
| CLK_DIV   | 系統時鐘除頻到 SCL 的除數 | 100 |

## 行為規格

### Write Transaction（延續階段三，需保持相容）
- [ ] 與階段三行為一致：`START → ADDR+W → [ACK] → DATA → [ACK] → ... → STOP`
- [ ] 支援 multi-byte write：每寫完一個 byte 並收到 ACK 後，自動進入下一個 byte
- [ ] 使用者需在每個 byte 前更新 `data_in`（或用 register 保持）
- [ ] `byte_count` 隨每個 byte 完成而遞增
- [ ] 傳完 `num_bytes` 個 byte 後進入 STOP（或 repeated start）

### Read Transaction（新功能）
- [ ] `START → ADDR+R → [ACK] → DATA_READ → [ACK/NACK] → ... → STOP`
- [ ] Address phase：`{slave_addr[6:0], 1'b1}`（R/W bit = 1 表示 read）
- [ ] Data phase：Master **釋放 SDA**（`sda_oe = 0`），用 shift register 在 SCL HIGH 中間點逐 bit 讀取 slave 送出的資料
- [ ] 每讀完 8 bits，將結果放入 `data_out` 並拉高 `data_valid` 一個 cycle
- [ ] Master ACK/NACK 控制：
  - 非最後一個 byte → Master 送 **ACK**（拉低 SDA），通知 slave 繼續送下一個 byte
  - 最後一個 byte（`byte_count == num_bytes - 1`）→ Master 送 **NACK**（釋放 SDA），通知 slave 停止
- [ ] `byte_count` 隨每個 byte 完成而遞增

### Repeated Start（新功能）
- [ ] 當 `repeated_start == 1` 時，transaction 結束不送 STOP，改送 **Repeated Start**
- [ ] Repeated Start 時序：SCL LOW → 釋放 SDA → 釋放 SCL（SCL HIGH）→ 拉低 SDA（= Start condition）
- [ ] Repeated Start 之後，Master 用新的 `slave_addr` 和 `rw` 開始新的 address phase
- [ ] 典型用途：write register address → repeated start → read data（不讓其他 master 搶 bus）
- [ ] `done` pulse 在 repeated start 後也要拉高，讓外部控制器知道可以設定下一筆 transaction 的參數

### FSM 狀態建議
- [ ] `IDLE` → `START` → `ADDR` → `ADDR_ACK` → `WRITE_DATA` / `READ_DATA` → `WRITE_ACK` / `READ_ACK` → ... → `STOP` / `REPEATED_START`
- [ ] 根據 `rw` 決定 address ACK 之後進入 `WRITE_DATA` 還是 `READ_DATA`
- [ ] 根據 `repeated_start` 決定最後進入 `STOP` 還是 `REPEATED_START`
- [ ] NACK 處理維持不變：收到非預期 NACK → 跳到 STOP，拉高 `ack_error`

### 輸出信號
- [ ] `busy`：從 `start` 觸發到 STOP/Repeated Start 完成
- [ ] `done`：STOP 或 Repeated Start 完成時 one-cycle pulse
- [ ] `ack_error`：非預期 NACK 時拉高，下次 transaction 清除
- [ ] `data_out`：read mode 時每個 byte 更新
- [ ] `data_valid`：read mode 每個 byte 完成時 one-cycle pulse
- [ ] `byte_count`：已完成的 byte 數，transaction 開始時歸零

## Testbench 要求

建立 `i2c_master_tb.v`，包含：

### Bus 建模
- SDA/SCL 用 `wire` + pullup（同階段三）

### Behavioral Slave
- 擴充階段三的 behavioral slave，增加 read 支援
- Slave 維護一個小型 register file（例如 4 個 8-bit registers）
- Write 時 slave 先接收 register address，再接收 data 存入 register
- Read 時 slave 從 register address 送出 data（MSB first）

### 測試情境
- [ ] **Single byte write**：維持與階段三相容（regression test）
- [ ] **Multi-byte write**：連續寫 2~3 bytes，驗證 `byte_count` 正確遞增
- [ ] **Single byte read**：Master 送 ADDR+R，slave 回 1 byte data，Master 送 NACK + STOP
- [ ] **Multi-byte read**：連續讀 2~3 bytes，驗證中間 byte Master 送 ACK、最後 byte 送 NACK
- [ ] **Register read（write + repeated start + read）**：
  1. Write transaction：送 register address（例如 `8'h02`）
  2. Repeated start
  3. Read transaction：讀回 register 內容
  4. 驗證讀到的值正確
- [ ] **NACK on address**：slave 不回 ACK，master 正確處理

## 提示

- 階段三的 `i2c_master.v` 是很好的起點，但需要重構 FSM 來區分 write/read data phase
- Read data phase 的關鍵：SDA ownership 切換。Write 時 master 驅動 SDA，read 時 **slave 驅動 SDA**，master 只在 SCL HIGH 中間點 sample
- Read 時 master 要送 ACK/NACK：這跟 write 時 slave 送 ACK 是鏡像關係。Master 在 ACK cycle 時要根據是否為最後一個 byte 決定驅動 SDA
- Repeated Start 的時序容易搞混：關鍵是先確保 SDA 是 HIGH（釋放），然後在 SCL HIGH 時拉低 SDA。如果前一個 cycle SDA 是 LOW，你需要先在 SCL LOW 時釋放 SDA
- Multi-byte 的狀態機設計：ACK 完成後判斷 `byte_count < num_bytes`，若還沒完就回到 DATA state 繼續
- Testbench 的 behavioral slave 可以用 `for` loop + `@(posedge scl)` 來逐 bit 送出 read data
