---
name: verilog-drill
description: "Verilog 學習練習產生器。根據專案中的 plan.md 產生 QA 問答題或建立實作練習資料夾。使用時機：(1) 使用者說 /verilog-drill 或要求出題、quiz、QA 練習 (2) 使用者要求建立實作練習、hands-on task、practice (3) 使用者想根據 plan 複習或準備面試。支援兩種模式：qa（問答題）和 practice（建立實作資料夾含 task.md）。"
---

# Verilog Drill

根據專案中的 plan（如 `I2C/plan.md`）產生學習練習，有兩種模式。

## 使用方式

```
/verilog-drill                    → 互動選擇模式和範圍
/verilog-drill qa                 → 根據 plan 出 QA 題目
/verilog-drill practice           → 建立實作練習資料夾
/verilog-drill qa day1            → 針對 Day 1 出題
/verilog-drill practice day3      → 針對 Day 3 建立實作練習
```

## 執行流程

### 1. 讀取 Plan

搜尋專案中的 `**/plan.md`，讀取其內容。若有多個 plan，詢問使用者要用哪一個。

### 2. 確定範圍

如果使用者沒有指定 day/section，列出 plan 中的所有 day/section 讓使用者選擇。

### 3. 根據模式執行

---

## QA 模式

從 plan 中指定範圍的「面試考點」和「實作內容」提取概念，產生 3-5 題問答題。

### 題目類型混合使用

- **概念題**：解釋原理（如：為什麼 SDA 要 open-drain？）
- **時序題**：描述信號行為（如：畫出 I2C write transaction 的時序）
- **Debug 題**：給一段有 bug 的 Verilog，找出問題
- **比較題**：比較兩種設計選擇的 tradeoff

### 出題格式

```
## Q1: [題目分類]
[題目內容]

<details>
<summary>提示</summary>
[一個小提示，不直接給答案]
</details>
```

出完題後等使用者回答。使用者回答後：
- 如果正確，簡短肯定，補充延伸知識
- 如果部分正確，指出遺漏的部分，用引導問題幫助使用者補完
- 如果錯誤，不直接給答案，用 2-3 個引導問題幫助使用者自己推導出正確答案
- 所有題目回答完畢後，給一個總結評語，指出需要加強的地方

---

## Practice 模式

在專案根目錄下建立 `drills/<topic>_<section>/` 資料夾，裡面包含 `task.md`。

### task.md 格式

```markdown
# [練習標題]

## 目標
[1-2 句描述這個練習要完成什麼]

## Module Interface

\`\`\`verilog
module <module_name> (
    input  wire        clk,
    input  wire        rst,
    // ... 完整的 port 定義，含註解說明每個 port 的用途
);
\`\`\`

## Parameter（如適用）

| Parameter | 說明 | 預設值 |
|-----------|------|--------|
| CLK_DIV   | ... | 100   |

## 行為規格
- [ ] [具體的功能需求 1]
- [ ] [具體的功能需求 2]
- [ ] ...

## 測試要點
- [需要在 testbench 中驗證的情境]

## 提示
- [不直接給答案，但指引方向的提示]
```

### 要求

- Interface 要完整列出所有 port，包含寬度和方向
- 行為規格用 checkbox 清單，讓使用者可以逐項確認
- 不要提供實作程式碼，只提供 interface 和規格
- 提示僅在使用者可能卡住的地方給引導方向
- 資料夾命名範例：`drills/i2c_day1/`, `drills/fsm_basics/`

---

## 注意事項

- 語言：使用繁體中文（與 CLAUDE.md conventions 一致）
- 不直接給答案，維持 tutor 角色
- 題目難度應從 plan 的內容推斷，面試考點 = 較高難度概念題，實作內容 = hands-on 題
