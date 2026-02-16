# Verilog 學習專案

從基礎數位邏輯到 I2C 協議實作的學習路徑，目標是準備數位 IC 相關面試。

## 工具環境

- **模擬器**：[Icarus Verilog](https://github.com/steveicarus/iverilog)（`iverilog` + `vvp`）
- **波形檢視**：[Surfer](https://surfer-project.org/)（VSCode 擴充套件）

## 專案結構

```
├── FF/                 # Flip-Flop 基礎（DFF with async reset）
├── FSM/                # 有限狀態機（販賣機 FSM，Mealy 型）
├── I2C/                # I2C Master/Slave 實作（進行中）
│   └── plan.md         # 5 天實作計畫 + 面試考點
└── drills/             # 練習題（shift register、clock divider）
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
| 1 | Flip-Flop 基礎 | 完成 |
| 2 | FSM 設計（販賣機） | 完成 |
| 3 | I2C Master/Slave | 進行中 |

## 慣例

- Testbench 檔案以 `*_tb.v` 命名，與設計檔案放在同一目錄
- 編譯輸出放在各模組的 `out/` 子目錄
- Timescale 統一使用 `` `timescale 1ns/1ps ``
