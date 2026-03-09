# I2C Master Bug Fix Log

## 階段 6 整合測試中發現的 bug

### Bug 1: WRITE state SDA 過早釋放導致假 STOP（critical）

**檔案**: `i2c_master.v` line 146（原）
**症狀**: Master 與 real slave 整合時，slave 在 data byte 結束時偵測到 STOP condition，中斷 transaction。
**根因**: WRITE state 在 `HIGH_MID` 時設定 `sda_oe <= 0`（釋放 SDA）。此時 SCL 為 HIGH。若最後一個 data bit 為 0（SDA 被拉低），釋放 SDA 會使 SDA 從 0→1，在 SCL HIGH 時形成 STOP condition。Slave 偵測到 `stop_condition = scl & ~sda_prev & sda`，立即回到 IDLE。
**修復**: 移除 WRITE state HIGH_MID 的 `sda_oe <= 0`，改由 ACK state 的 `LOW_MID`（SCL LOW 時）釋放 SDA。ACK state 原本就有 `sda_oe <= 0` 的邏輯。
**影響**: 此 bug 在 standalone testbench 中不會出現，因為 behavioral slave task 不會偵測 STOP condition。只有接上 real slave module 才會觸發。

### Bug 2: data_valid 未在 always block 頂層清除

**檔案**: `i2c_master.v` line 103（原）
**症狀**: `data_valid` 在 READ state 的 `HIGH_MID` 被設為 1 後，直到 ACK state 的 `HIGH_MID` 才被清為 0，中間可能持續數十個 clock cycles。Testbench 會誤讀多次。
**根因**: `done` 在 always block 頂層有 `done <= 0;` 確保只持續一個 cycle，但 `data_valid` 沒有對應的清除。
**修復**: 在 always block 頂層（`done <= 0;` 之後）加入 `data_valid <= 0;`，確保 `data_valid` 也是 one-cycle pulse。

### Bug 3: STOP state SCL 不 clock，slave 無法釋放 ACK（critical）

**檔案**: `i2c_master.v` SCL always block（line 75 原）
**症狀**: 所有 transaction 後 slave 無法偵測 STOP condition，導致下一筆 transaction 的 address byte 被當成 data 處理。
**根因**: SCL always block 中 `IDLE, START, STOP: scl_oe <= 0` 使 STOP state 保持 SCL HIGH。Slave 在 ACK state 等待 `scl_falling` 釋放 SDA，但 SCL 不再 clock。Slave 持續拉低 SDA（ACK），master 釋放 SDA 時 SDA 無法上升，STOP condition（SDA 0→1 while SCL HIGH）永遠不會發生。
**修復**: 從 SCL idle list 移除 STOP：`IDLE, START: scl_oe <= 0`。STOP state 改用 default case 正常 clock SCL，讓 slave 在 scl_falling 時釋放 ACK，之後 master 才執行 SDA low→high 產生正確的 STOP condition。
**影響**: 同 Bug 1，standalone testbench 中 behavioral slave 不受影響。Real slave 才會觸發。

---

## 待修正：Slave 端已知問題

### Bug 4: Slave 在 READ-ACK 階段誤判 STOP condition（未修正）

**檔案**: `i2c_slave.v`
**症狀**: Master 執行 READ transaction 時，slave 在 ACK window 中偵測到假 STOP，導致 transaction 提前中斷。Repeated start 場景尤其容易觸發。
**根因**: Master READ 時在 ACK phase 會釋放 SDA（準備送 ACK/NACK），若此時 SCL 為 HIGH，SDA 從 LOW→HIGH 的變化會被 slave 的 `stop_condition` 偵測邏輯誤判為 STOP。
**修復方案**: 已在 i2c_demo 專案的 slave 中實作修正（`/Users/rswa/Dev/verilog/i2c_demo/backend/sim/rtl/i2c_slave.v`）。修正方式：
- 新增 `in_read_ack_window` flag，在 slave 送出 read data 的最後一個 bit 到下一個 SCL falling edge 之間設為 1
- 修改 stop_condition 為 `stop_condition = scl & ~sda_prev & sda & ~in_read_ack_window`
- 讓 slave 在 read ACK window 期間忽略 SDA 變化

**參考**: 從 i2c_demo 的 slave 把 `in_read_ack_window` 相關邏輯移植過來即可。
