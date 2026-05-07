# V9-2 Ticket 04：採集者詳細頁視覺升級

**狀態：** 📋 規劃中

**依賴：** V9-1 T04 NPC WebP 圖片已生成（`npc_gatherer_1/2/3/4.webp`）

---

## 目標

`GathererDetailSheet` 目前頁首用 32×32 小圖示顯示 NPC，
與 T01 卡片大圖（72×72）形成落差。

將詳細頁頭部改為英雄個人資料卡風格：
大圖置中 + 名稱 + 技能加成摘要，讓詳細頁有「認識這個 NPC」的感覺。

---

## 新 UI 設計

```
┌──────────────────────────────────────────────┐
│                                              │
│           ┌──────────────┐                  │
│           │  [NPC 圖片]   │                  │
│           │   96×96      │                  │
│           │   圓角 16    │                  │
│           └──────────────┘                  │
│                                              │
│           伐木工                             │
│           Tier 2 · 技能：高效率採集 +15%     │
│                                              │
└──────────────────────────────────────────────┘
```

**頭部 View 程式碼：**

```swift
private var npcHeaderView: some View {
    VStack(spacing: 10) {
        Image(webp: "npc_\(npcDef.actorKey)")
            .resizable()
            .scaledToFill()
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

        VStack(spacing: 4) {
            Text(npcDef.name)
                .font(.title3).fontWeight(.bold)

            if let player {
                let tier = player.tier(for: npcDef.actorKey)
                HStack(spacing: 6) {
                    TierBadgeView(tier: tier)
                    if tier > 0 {
                        Text(npcDef.skillSummary(tier: tier))  // 現有技能加成摘要
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
}
```

---

## 修改範圍

### `Views/GathererDetailSheet.swift`

**1. 現有頁首 detailSection 的 NPC 小圖示改為 `npcHeaderView`**

目前（Line ~137）：
```swift
HStack {
    Image(systemName: npcDef.icon)  // 或已改為 Image(webp:) 32×32
    Text(npcDef.name)
    ...
}
```

改為：
```swift
// Section 之外，放在 List 最頂端（listRowBackground Clear）
Section {
    npcHeaderView
}
.listRowBackground(Color.clear)
.listRowInsets(.zero)
```

**2. 其他 Section 不動**

- 技能樹升級 Section
- 採集地點列表 Section
- 採集 / 閒置狀態 Section

---

## 不改動範圍

- `GathererNpcDef` 靜態資料
- 技能效果計算邏輯
- 採集地點選擇行為

---

## 風險注意事項

**圖片資源必須先到位（V9-1 T04 依賴）：**
`npcHeaderView` 使用 `Image(webp: "npc_\(npcDef.actorKey)")`，
需要 `npc_gatherer_1.webp`、`npc_gatherer_2.webp`、`npc_gatherer_3.webp`、`npc_gatherer_4.webp` 存在。

實作前先確認：
```bash
ls IdleBattleRPG/Resources/npc_gatherer_*.webp
```
若圖片不存在，`Image(webp:)` extension 會顯示空白，不會 crash，但視覺會爛掉。
圖片未到位前先跳 T02/T03。

---

## 驗證方式

1. 確認 `npc_gatherer_1/2/3/4.webp` 存在於 `Resources/`
2. `xcodebuild` 通過，無新警告
3. 模擬器：
   - 點擊任意採集者 → 詳細頁頂端顯示 96×96 大圖（圖片清晰，非空白）
   - 圖片風格與 T01 Grid 卡片一致
   - Tier badge + 技能摘要正確顯示
   - 詳細頁其餘內容（技能升級、地點選擇）正常運作
