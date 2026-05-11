# V10-3 Ticket 02：移除 AdventureView Step 4 重複橫幅

## 問題

Step 4 在 AdventureView 同時出現兩份指引：
1. **tutorialHintBanner**（BaseView 頂部）：「前往冒險頁，挑戰金穗之野的菁英敵人！」
2. **tutorialStep4BannerSection**（AdventureView 內）：「前往金穗之野，挑戰穀倉前道的菁英敵人！打敗他，贏得防具鍛造材料。」

兩者文字幾乎相同，同時顯示造成畫面重複。

## 方案

刪除 `AdventureView.tutorialStep4BannerSection` 及相關 `@ViewBuilder` 宣告。

`tutorialHintBanner` 已足夠引導玩家。

## 改動

**`IdleBattleRPG/Views/AdventureView.swift`**

- 刪除 `tutorialStep4BannerSection` 整個 `@ViewBuilder` function（約 15 行）
- 刪除 `body` 內對它的引用

## 驗證

Step 4 進入 AdventureView → 只看到 BaseView 頂部 banner，不再有第二個引導 section。

## 狀態：✅ 已完成

目前 `AdventureView` 已不再保留獨立的 `tutorialStep4BannerSection`，step 4 主要由基地頂部 `tutorialHintBanner` 引導。
