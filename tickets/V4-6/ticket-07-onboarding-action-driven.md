# Ticket T07 — 新手引導改為動作驅動

## 問題
`OnboardingBannerView` 的「下一步」按鈕讓玩家可以在不執行任何操作的情況下跳過引導，
導致引導失去意義。

## 解法
移除手動「下一步」按鈕，改為真實行為觸發步驟推進：
- Step 0 → 1：實際派出採集者時自動推進
- Step 1 → 2：實際開始鑄造時自動推進
- Step 2 → 3：實際出征時自動推進

Banner 保留說明文字和行動提示文字，但不再有可點擊的跳過按鈕。

## 修改的檔案

### `IdleBattleRPG/Views/OnboardingBannerView.swift`
- 移除 `stepSection` 的 `buttonLabel` 參數與 `Button`
- 改為顯示 `hint` 行動提示文字（"派出採集者後自動進入下一步" 等）
- 保留 `onAdvance` 閉包參數（相容性，不再使用）

### `IdleBattleRPG/Views/GathererDetailSheet.swift`
`startGather()` 成功後呼叫 `viewModel.advanceOnboarding(expectedStep: 0, ...)`

### `IdleBattleRPG/Views/CraftSheet.swift`
`startCraft()` 成功後呼叫 `viewModel.advanceOnboarding(expectedStep: 1, ...)`

### `IdleBattleRPG/Views/AdventureView.swift`
`launchFloor()` 成功後直接推進 `player.onboardingStep 2 → 3`

## 驗證
- 新玩家不按任何按鈕，派出採集者後 onboardingStep 自動變為 1
- 開始鑄造後 onboardingStep 自動變為 2
- 出征後 onboardingStep 自動變為 3，Banner 消失
