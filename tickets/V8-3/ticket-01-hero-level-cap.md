# V8-3 Ticket 01：英雄等級上限 Lv20 → Lv30

**狀態：** ✅ 完成

**依賴：** 無

---

## 目標

將英雄等級上限從 20 提升至 30，補齊 Lv21–30 的 EXP 門檻表，為 T02 進階技能（Lv23/28 解鎖）建立前提。

---

## 修改細節

### `AppConstants.swift`

```swift
// Game 命名空間
static let heroMaxLevel = 30   // 原為 20

// ExpThreshold.table 新增
21: 23_500, 22: 29_000, 23: 35_500, 24: 43_000, 25: 52_000,
26: 62_500, 27: 75_000, 28: 90_000, 29: 108_000, 30: 130_000
```

`CharacterProgressionService`、`CharacterView`、`CharacterViewModel` 直接讀取 `heroMaxLevel` 常數，無需個別修改。升級獎勵規則（+3 stat / +1 talent / +1 skill）不變。

---

## 修改檔案

- `AppConstants.swift`

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] DevMode「升級」按鈕可以升到 Lv30
- [ ] Lv21 後升級仍正確給予屬性點 / 天賦點 / 技能點
- [ ] Lv30 後「升級」按鈕不再出現（已達上限）
