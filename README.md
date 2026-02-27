# Verilog 學習專案

從基礎數位邏輯到 I2C 協議實作的學習練習紀錄。

## 工具環境

- **模擬器**：[Icarus Verilog](https://github.com/steveicarus/iverilog)（`iverilog` + `vvp`）
- **波形檢視**：[Surfer](https://surfer-project.org/)（VSCode 擴充套件）

## 專案結構

```
├── FF/                 # Flip-Flop 基礎（DFF with async reset）
├── FSM/                # 有限狀態機（販賣機 FSM，Mealy 型）
├── plan.md             # 完整學習計畫（階段 1~8）
└── drills/             # 實作練習（每個資料夾含 task.md 規格 + 實作）
    ├── basic_clock_divider/
    ├── tri_state_bus/
    ├── edge_detector/
    ├── i2c_warmup_clock_divider/
    ├── i2c_warmup_shift_register/
    ├── i2c_master_single_byte_write/
    ├── i2c_master_read_repeated_start/
    └── i2c_slave_controller/          # ← 目前進度
```

## 編譯與模擬

```bash
# 通用流程：編譯 → 執行 → 看波形
iverilog -o out/<name> <module>.v <testbench>.v
vvp out/<name>
# 開啟產生的 .vcd 檔案檢視波形
```

範例（Flip-Flop）：

```bash
iverilog -o out/ff FF/ff.v FF/ff_tb.v
vvp out/ff
```

## 學習路線

| 階段 | 主題 | 狀態 |
|------|------|------|
| 1 | 數位基礎元件（DFF、FSM） | 完成 |
| 2 | I2C 暖身練習（clock divider、tri-state、edge detector、shift register） | 完成 |
| 3 | I2C Master — Single Byte Write | 完成 |
| 4 | I2C Master — Read + Repeated Start + Multi-byte | 完成 |
| 5 | I2C Slave Controller | 進行中 |
| 6 | 系統整合 + 驗證 | — |
| 7 | Edge Cases + Demo 準備 | — |
| 8 | cocotb + FastAPI 互動式測試平台（Extra） | — |

## Drills 練習系統

每個 drill 是一個獨立的實作練習，對應 `plan.md` 中的一個階段或子項目。

### 結構

每個 `drills/<name>/` 資料夾包含：

| 檔案 | 說明 |
|------|------|
| `task.md` | 練習規格：module interface、行為規格（checkbox）、testbench 要求、提示 |
| `<module>.v` | 自己實作的設計檔案 |
| `<module>_tb.v` | 自己撰寫的 self-checking testbench |
| `out/` | 編譯輸出 |

### `/verilog-drill` — Claude Code Skill

本專案搭配 [Claude Code](https://claude.ai/claude-code) 的自訂 skill，可自動根據 `plan.md` 產生練習。

```
/verilog-drill                    → 互動選擇模式和範圍
/verilog-drill qa                 → 出 QA 問答題（概念、時序、debug、比較題）
/verilog-drill practice           → 建立新的實作練習資料夾（含 task.md）
/verilog-drill qa 階段4           → 針對特定階段出題
/verilog-drill practice 階段5     → 針對特定階段建立練習
```

**QA 模式**：根據 plan 中的實作內容和面試考點出 3~5 題，涵蓋概念、時序、debug、比較題型。回答後會給予回饋和引導。

**Practice 模式**：在 `drills/` 下建立新資料夾，產生 `task.md` 規格文件。只提供 interface 和行為規格，不給實作程式碼。

## 慣例

- Testbench 檔案以 `*_tb.v` 命名，與設計檔案放在同一目錄
- 編譯輸出放在各模組的 `out/` 子目錄
- Timescale 統一使用 `` `timescale 1ns/1ps ``
