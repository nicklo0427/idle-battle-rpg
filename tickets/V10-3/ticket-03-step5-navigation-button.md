# V10-3 Ticket 03：Step 5「前往荒野探索 →」導覽按鈕（需決策）

## 背景

Step 5 在 TailorSheet 有一個「前往荒野探索 →」按鈕，它做兩件事：
1. 把 `onboardingStep` 從 5 推進到 6
2. 把 tab 切換到冒險頁（selectedTab = 1）

## 問題

這個按鈕與其他引導按鈕不同，它並非「同一個功能的重複按鈕」，而是一個純引導導覽按鈕，沒有對應的正常 UI 按鈕。

但它仍然是一個使用者必須按的「引導專屬按鈕」，與使用者提出的「引導按鈕應整合進原生 UI」原則衝突。

## 兩個選項

### 選項 A：移除按鈕，改為 onAppear 自動推進
- TailorSheet step 5 只顯示文字說明（保留氣泡文字）
- 當使用者自行切換到 AdventureView 時，`onAppear` 自動把 step 5 → 6
- 優點：完全無額外引導按鈕
- 缺點：使用者需要自己找到冒險頁，引導性稍弱

### 選項 B：保留，但調整視覺
- 這個按鈕本質是「導航提示」而非「功能捷徑」，語意不同
- 保留文字提示 + 按鈕，但不視為問題
- 調整按鈕樣式，讓它看起來更像「前往」而非「執行動作」（例如用 `.buttonStyle(.plain)` 加箭頭圖示）

### 選項 C（推薦）：改成 onAppear 自動推進 + 強化 Banner 說明
- 移除 tab 切換按鈕
- Step 5 TailorSheet 只顯示情境說明：「護甲需要獸皮，去荒野採集吧。」
- tutorialHintBanner 已顯示「前往「冒險」→ 金穗之野，探索獲取防具素材」
- AdventureView 的 `onAppear` 裡，若 `onboardingStep == 5`，自動推進到 6
- 效果：Banner 引導玩家切換 tab，進入 Adventure 就自動推進

## 決策

採用 **選項 C：onAppear 自動推進 + 強化 Banner 說明**。

目前 `AdventureView.onAppear` 會在玩家進入冒險頁時，將 `onboardingStep == 5` 自動推進到 6；`TailorSheet` step 5 只保留情境說明，不再顯示「前往荒野探索」按鈕。

## 相關檔案

- `IdleBattleRPG/Views/TailorSheet.swift`（步驟 5 section）
- `IdleBattleRPG/Views/AdventureView.swift`（onAppear 推進）

## 狀態

✅ 已完成
