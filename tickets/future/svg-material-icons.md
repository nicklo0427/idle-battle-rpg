# Future：道具 / 素材 SVG Icon 替換

**狀態：** 💡 未來規劃
**優先級：** P1（區域素材）/ P2（通用素材）/ P3（裝備槽）

---

## 背景

目前素材、道具 icon 使用系統 emoji（`mat.icon`）。
通用素材（木材、礦石等）辨識度尚可，
但區域特殊素材（裂牙皇徽、誓言刻文碎片等冷僻名稱）沒有對應 emoji，
視覺表達力不足，且難以維持統一的遊戲風格。

### SVG 方案優勢

- 無限縮放，任何尺寸都清晰
- Asset Catalog **Template Image** 模式可動態換色（`.foregroundStyle()`）
- 統一遊戲視覺語言，比 emoji 更有「遊戲感」
- 比 WebP 檔案更小

---

## 範圍（分優先級）

### P1 — 區域素材（16 種）⭐ 最值得做

這些素材名稱冷僻，emoji 根本找不到對應圖示：

| 區域 | 素材名稱 | Asset 名稱 |
|---|---|---|
| 荒野邊境 | 舊驛站徽記 | `mat_old_post_badge` |
| 荒野邊境 | 乾燥獸皮捆 | `mat_dried_hide_bundle` |
| 荒野邊境 | 裂角骨 | `mat_split_horn_bone` |
| 荒野邊境 | 裂牙皇徽 | `mat_rift_fang_royal_badge` |
| 廢棄礦坑 | 礦燈銅夾 | `mat_mine_lamp_copper_clip` |
| 廢棄礦坑 | 坑道鐵夾 | `mat_tunnel_iron_clip` |
| 廢棄礦坑 | 礦脈石板 | `mat_vein_stone_slab` |
| 廢棄礦坑 | 石燕核 | `mat_stone_swallow_core` |
| 古代遺跡 | 遺跡封印環 | `mat_relic_seal_ring` |
| 古代遺跡 | 誓言刻文碎片 | `mat_oath_inscription_shard` |
| 古代遺跡 | 前神殿夾件 | `mat_fore_shrine_clip` |
| 古代遺跡 | 古王核心 | `mat_ancient_king_core` |
| 沉落王城 | 沉沒盧恩碎片 | `mat_sunken_rune_shard` |
| 沉落王城 | 深淵晶體碎片 | `mat_abyssal_crystal_drop` |
| 沉落王城 | 溺冠碎片 | `mat_drowned_crown_fragment` |
| 沉落王城 | 沉王封印 | `mat_sunken_king_seal` |

### P2 — 通用素材（選做）

木材、礦石、獸皮等 emoji 辨識度已夠，可維持現狀，或補齊以求完整一致性。

### P3 — 裝備槽 icon（低優先）

⚔️🛡️💍 emoji 效果夠好，暫不替換。

---

## 技術方案

### Asset Catalog 設定（每張 SVG）

1. 拖入 `Assets.xcassets`
2. **Render As** → Template Image
3. **Preserve Vector Data** → 勾選

```swift
Image("mat_old_post_badge")
    .resizable().scaledToFit()
    .frame(width: 28, height: 28)
    .foregroundStyle(.secondary)   // 可動態換色
```

### 程式碼改動（`StaticData/MaterialType.swift`）

新增 `svgName` computed property，有對應 SVG 的才回傳名稱：

```swift
var svgName: String? {
    switch self {
    case .oldPostBadge:          return "mat_old_post_badge"
    case .driedHideBundle:       return "mat_dried_hide_bundle"
    case .splitHornBone:         return "mat_split_horn_bone"
    case .riftFangRoyalBadge:    return "mat_rift_fang_royal_badge"
    // ...其餘區域素材
    default: return nil   // 通用素材繼續用 emoji
    }
}
```

### `materialCard` 改動（`Views/CharacterView.swift`）

優先用 SVG，fallback emoji：

```swift
@ViewBuilder
private func materialCard(_ mat: MaterialType, amount: Int) -> some View {
    VStack(spacing: 5) {
        if let name = mat.svgName {
            Image(name)
                .resizable().scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(.secondary)
        } else {
            Text(mat.icon).font(.system(size: 26))
        }
        Text(mat.displayName)
            .font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
        Text("×\(amount)")
            .font(.caption2).fontWeight(.semibold).monospacedDigit()
    }
    // ...card styling 不變
}
```

---

## 所需 Assets

- 區域素材 SVG × 16，規格：128×128 px，單色透明底
- 生成 prompt 格式參考：`tickets/V9-1/ticket-07-character-ui-icons.md`
- 建議用 AI 生成後以 Inkscape / Illustrator 向量化輸出 `.svg`

---

## 依賴

- `MaterialType` 需新增 `svgName: String?`
- Assets.xcassets 正常運作（已確認）
- `materialCard` 函式已存在（`CharacterView.swift`）
