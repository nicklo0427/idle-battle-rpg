# V9-1 Ticket 06.1：Resources 資料夾整理

**狀態：** 📋 規劃中

---

## 現況

目前 `IdleBattleRPG/Resources/` 共 52 個 WebP，全部放在同一層（平坦結構）：

```
Resources/
├── boss_*_4.webp          ×4
├── elite_*_*.webp         ×16
├── mob_*_*.webp           ×12   ← T06 每樓層
├── mob_{region}.webp      ×4    ← ⚠️ 未使用（見下）
├── icon_*.webp            ×3
├── npc_*.webp             ×9
└── region_*.webp          ×4
```

---

## 問題一：4 張閒置圖片

T05 Group C 原規劃用「區域層級」mob 剪影作為普通樓層圓圈背景，命名為：

```
mob_wildland.webp
mob_abandoned_mine.webp
mob_ancient_ruins.webp
mob_sunken_city.webp
```

T06 實作後改為每樓層各一張（`mob_wildland_1~3` 等），
上述 4 張**從未在程式碼中被引用**，可安全刪除。

**刪除指令：**
```bash
cd IdleBattleRPG/Resources
rm mob_wildland.webp mob_abandoned_mine.webp mob_ancient_ruins.webp mob_sunken_city.webp
```
刪除後執行 `xcodegen generate`。

---

## 問題二：是否要分資料夾？

### 分資料夾的好處
- 一眼區分類型，日後超過 100 張也不混亂

### 分資料夾的代價
| 項目 | 影響 |
|---|---|
| `Image+WebP.swift` 需改 | `Bundle.main.url(forResource:withExtension:subdirectory:)` |
| 所有 `Image(webp:)` 呼叫要加前綴 | 約 20+ 處 |
| 每次新增圖片要確認放對資料夾 | 多一步驟 |
| xcodegen generate 需重跑 | 同現在 |

### 建議結構（如決定分）
```
Resources/
├── bosses/      boss_*.webp
├── elites/      elite_*.webp
├── icons/       icon_*.webp
├── mobs/        mob_*_*.webp
├── npcs/        npc_*.webp
└── regions/     region_*.webp
```

**結論：現階段建議只做「刪除 4 張閒置圖片」，分資料夾列為 backlog，待圖片數量達 80+ 張再評估。**

---

## 實作步驟

1. 刪除 4 張閒置 WebP
2. `xcodegen generate`
3. Build 確認無錯誤

## 修改檔案

- `IdleBattleRPG/Resources/`（刪除 4 檔）
