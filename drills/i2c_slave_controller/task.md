# I2C Slave Controller

## 目標
實作一個 I2C Slave Controller，能在 I2C bus 上被 Master 定址，支援 register read/write。Slave 內建 8 個 8-bit registers，Master 可透過標準 I2C protocol 寫入資料或讀回 register 內容。

## Module Interface

```verilog
module i2c_slave (
    input  wire        clk,          // 系統時鐘
    input  wire        rst_n,        // 非同步 reset（active low）

    // 配置
    input  wire [6:0]  slave_addr,   // 本 slave 的 7-bit address

    // 狀態輸出
    output reg         busy,         // transaction 進行中
    output reg  [7:0]  reg_addr,     // 目前操作的 register address
    output reg  [7:0]  reg_data_out, // 最近一次寫入的 data（debug 用）
    output reg         write_valid,  // 有新資料被寫入 register（one-cycle pulse）

    // I2C bus
    input  wire        scl,          // I2C clock（由 Master 驅動）
    inout  wire        sda           // I2C data（open-drain, bidirectional）
);
```

## 內部結構

| 元件 | 說明 |
|------|------|
| Register file | `reg [7:0] registers [0:7]`，8 個 8-bit registers |
| Register pointer | 指向目前操作的 register 位址，write 時 auto-increment |

## 行為規格

### Start / Stop Condition Detection
- [ ] 偵測 Start condition：SCL HIGH 時 SDA 出現 **falling edge**
- [ ] 偵測 Stop condition：SCL HIGH 時 SDA 出現 **rising edge**
- [ ] 偵測 Repeated Start：在 transaction 進行中再次偵測到 Start condition
- [ ] 注意：需要用系統時鐘 sample SCL 和 SDA，做 edge detection（不能直接用 SCL 當 clock）

### Address Phase
- [ ] Start 之後，接收 8 bits（7-bit address + 1-bit R/W）
- [ ] 比對收到的 address 與 `slave_addr`
- [ ] Match → 在第 9 個 SCL cycle 驅動 SDA LOW（送 ACK）
- [ ] 不 match → 不驅動 SDA（維持 hi-Z），回到 IDLE 等待 Stop

### Write Transaction（Master → Slave）
- [ ] Address phase R/W bit = 0
- [ ] ACK 後，接收第一個 data byte → 存為 **register address**（register pointer）
- [ ] 後續 data bytes → 依序寫入 `registers[reg_addr]`，每寫一個 byte `reg_addr` auto-increment
- [ ] 每個 data byte 接收完成後送 ACK
- [ ] `write_valid` 在每次寫入 register 時拉高一個 cycle
- [ ] 收到 Stop 結束 transaction

### Read Transaction（Slave → Master）
- [ ] Address phase R/W bit = 1
- [ ] ACK 後，Slave 從 `registers[reg_addr]` 讀出資料，透過 SDA **逐 bit 送出**（MSB first）
- [ ] 送完 8 bits 後，**釋放 SDA**，等待 Master 送 ACK 或 NACK
- [ ] Master ACK → `reg_addr` auto-increment，繼續送下一個 byte
- [ ] Master NACK → 停止送資料，等待 Stop 或 Repeated Start
- [ ] 注意：Read 時 Slave 要在 **SCL LOW** 時切換 SDA

### FSM 狀態建議
- [ ] `IDLE` → `ADDR_RECV` → `ADDR_ACK` → `REG_ADDR_RECV` / `READ_DATA` → `DATA_ACK` → ... → `IDLE`
- [ ] Write path: `ADDR_ACK` → `REG_ADDR_RECV` → `REG_ADDR_ACK` → `WRITE_DATA` → `WRITE_ACK` → ...
- [ ] Read path: `ADDR_ACK` → `READ_DATA` → `READ_ACK` → ...
- [ ] 收到 Stop 或偵測到地址不 match → 回 IDLE

### SDA 驅動規則
- [ ] 只在需要時驅動 SDA（ACK phase、Read data phase），其餘時間釋放（hi-Z）
- [ ] `assign sda = sda_oe ? sda_out : 1'bz;`

## Testbench 要求

建立 `i2c_slave_tb.v`，包含：

### Bus 建模
- SDA/SCL 用 `wire` + pullup（同之前的 drill）

### Behavioral Master
- 用 task 實作一個 behavioral master，能產生 I2C write/read transaction
- Master 驅動 SCL 和 SDA，模擬真實 I2C timing

### 測試情境
- [ ] **Single byte write**：寫一個 byte 到 register 0，驗證 register 內容正確
- [ ] **Multi-byte write**：連續寫 3 bytes（reg addr + 2 data bytes），驗證 auto-increment
- [ ] **Single byte read**：先 write 設定 register address，再用新 transaction 讀回 1 byte
- [ ] **Multi-byte read**：連續讀 2 bytes，驗證 auto-increment 和 ACK/NACK
- [ ] **Register read（write + repeated start + read）**：write reg addr → repeated start → read data back
- [ ] **Address mismatch**：送一個不同的 address，驗證 slave 不回 ACK

## 提示

- 最大的挑戰是 **Start/Stop detection**。你不能把 SCL 當 clock 用（`@(posedge scl)`），因為 Start/Stop 發生在 SCL HIGH 期間，不是 edge。用系統時鐘 sample SCL 和 SDA，做 edge detection
- Slave 沒有自己的 clock divider——SCL 是由 Master 驅動的。Slave 用系統時鐘偵測 SCL 的 rising/falling edge 來知道什麼時候該 sample 或切換 SDA
- Write path 的第一個 data byte 比較特殊，它是 **register address** 而非資料。你可能需要一個 flag 來區分
- Read 時 Slave 要在 SCL falling edge 切換 SDA，確保 Master 在 SCL HIGH 中間點 sample 時資料已穩定
- 想想看之前 drill 做過的 edge detector 怎麼應用在這裡
