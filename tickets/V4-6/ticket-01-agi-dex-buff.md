# Ticket T01 — AGI/DEX 戰力權重提升 + UI 說明

## 問題
AGI/DEX 在戰力公式中權重為 1:1，與 ATK（2:1）、DEF（1.5:1）相比投入回報最低。
玩家看不出 AGI/DEX 的實際作用，感覺是「廢屬性」。

## 解法
1. 將 AGI/DEX 戰力公式權重提升至 1.5:1（與 DEF 相同）
2. 在 `statAllocRow` 加上副標題提示（"ATB 速度" / "暴擊率"）

## 修改的檔案

### `IdleBattleRPG/Models/HeroStats.swift`
戰力公式：`totalAGI + totalDEX` → `Int(Double(totalAGI) * 1.5) + Int(Double(totalDEX) * 1.5)`

### `IdleBattleRPG/Views/CharacterView.swift`
`statAllocRow` 新增 `hint: String?` 參數：
- AGI 行加 `hint: "ATB 速度"`
- DEX 行加 `hint: "暴擊率"`

## 驗證
- 投入 6 點 AGI 的戰力增加 = 9（1.5×6），而非原本的 6
- 角色頁 AGI 行顯示副標 "ATB 速度"，DEX 行顯示 "暴擊率"
