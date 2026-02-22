# I2C Master — Single Byte Write

## 目標
實作一個 I2C Master，能夠執行完整的 single byte write transaction：發送 Start condition、7-bit slave address + W、1 byte data，最後發送 Stop condition。包含 ACK/NACK 處理。

## Module Interface

```verilog
module i2c_master (
    input  wire        clk,         // 系統時鐘（遠快於 SCL，例如 50MHz）
    input  wire        rst_n,       // 非同步 reset（active low）
    input  wire        start,       // 外部觸發：開始一筆 transaction
    input  wire [6:0]  slave_addr,  // 7-bit slave address
    input  wire [7:0]  data_in,     // 要寫入的 8-bit data
    output reg         busy,        // transaction 進行中
    output reg         done,        // transaction 完成（one-cycle pulse）
    output reg         ack_error,   // slave 回 NACK（address 或 data phase）
    output wire        scl,         // I2C clock（open-drain）
    inout  wire        sda          // I2C data（open-drain, bidirectional）
);
```

## Parameter

| Parameter | 說明 | 預設值 |
|-----------|------|--------|
| CLK_DIV   | 系統時鐘除頻到 SCL 的除數（SCL freq = clk freq / CLK_DIV） | 100 |

## 行為規格

### FSM 狀態機
- [ ] `IDLE`：等待 `start` 信號，SCL/SDA 都釋放（HIGH）
- [ ] `START`：SCL HIGH 時，SDA 從 HIGH 拉到 LOW（Start condition）
- [ ] `ADDR`：逐 bit 送出 `{slave_addr[6:0], 1'b0}`（MSB first，W=0），共 8 個 SCL cycle
- [ ] `ACK_ADDR`：Master 釋放 SDA，在 SCL HIGH 時讀取 slave 的 ACK/NACK
- [ ] `DATA`：逐 bit 送出 `data_in[7:0]`（MSB first），共 8 個 SCL cycle
- [ ] `ACK_DATA`：Master 釋放 SDA，在 SCL HIGH 時讀取 slave 的 ACK/NACK
- [ ] `STOP`：SCL HIGH 時，SDA 從 LOW 拉到 HIGH（Stop condition）
- [ ] NACK 處理：任一 ACK phase 收到 NACK → 跳到 `STOP`，拉高 `ack_error`

### SCL 時序
- [ ] SCL 由系統時鐘除頻產生，占空比 50%
- [ ] SDA 只在 **SCL LOW** 時切換（Start/Stop 除外）
- [ ] Start condition：SCL HIGH 期間 SDA ↓
- [ ] Stop condition：SCL HIGH 期間 SDA ↑

### Open-Drain 建模
- [ ] SCL 和 SDA 都是 open-drain：只能「拉低」或「釋放」，不能主動驅動 HIGH
- [ ] 使用 `assign sda = sda_oe ? 1'b0 : 1'bz;` 模式（oe=1 拉低，oe=0 釋放）
- [ ] SCL 同理：`assign scl = scl_oe ? 1'b0 : 1'bz;`

### 輸出信號
- [ ] `busy`：從 `start` 觸發到 `STOP` 完成期間為 HIGH
- [ ] `done`：transaction 結束時拉高一個 cycle（不論成功或 NACK）
- [ ] `ack_error`：任一 ACK phase 收到 NACK 時拉高，直到下一次 transaction 清除

## Testbench 要求

建立 `i2c_master_tb.v`，包含：

### Bus 建模
- SDA/SCL 用 `wire` 連接 master 和 testbench
- 加上 pullup：`pullup(sda); pullup(scl);`（或用 `assign (weak0, weak1) sda = 1'b1;`）

### Behavioral Slave（用 task 模擬）
- 不需要寫完整 slave module，用 testbench task 模擬 slave 回應
- Slave 在 ACK cycle 時拉低 SDA 回 ACK
- 準備一個 NACK 的 test case（slave 不拉低 SDA）

### 測試情境
- 正常 write：送 address + data，slave 都回 ACK，確認 SDA 上的波形正確
- NACK on address：slave 不回 ACK，master 應該直接送 STOP 並拉高 `ack_error`
- NACK on data：address ACK 但 data NACK，master 送 STOP 並拉高 `ack_error`
- 驗證 Start/Stop condition 時序正確
- 驗證 SDA 只在 SCL LOW 時切換（除了 Start/Stop）

## 提示

- 你之前做的 clock divider 和 shift register 可以直接**內嵌**到 FSM 裡，不一定要 instantiate 成獨立 module
- SCL 時序的關鍵：你需要知道 SCL 的哪個「時刻」做什麼事。可以用 clock divider 的 counter 來區分四個 phase：SCL 拉低、SCL low 中間（切 SDA）、SCL 釋放、SCL high 中間（sample SDA）
- FSM 的 state transition 不是每個 system clock 切一次，而是**每個 SCL cycle 切一次**（或每個 bit 切一次）
- Testbench 裡的 behavioral slave 可以用 `@(posedge scl)` 來偵測 SCL 上升緣，在正確的時機回 ACK
- Open-drain 的 `1'bz` 搭配 pullup 後，在 bus 上會讀到 `1'b1`
