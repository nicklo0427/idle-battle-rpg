# V6-2 Ticket 06：天賦重置

**狀態：** ✅ 完成
**版本：** V6-2
**依賴：** T08（路線互斥 + maxLevel）
**修改檔案：**
- `IdleBattleRPG/AppConstants.swift`
- `IdleBattleRPG/Services/TalentService.swift`
- `IdleBattleRPG/Views/CharacterView.swift`

---

## 說明

讓玩家可以重置所有已投入的天賦節點，退還全部天賦點，並解除路線互斥鎖定，以便重新選擇天賦路線。
消耗固定金幣費用，防止無成本無限切換。

---

## AppConstants 新增

```swift
// AppConstants.swift
extension AppConstants {
    enum Talent {
        static let resetCost = 500   // 重置所有天賦的金幣費用
    }
}
```

---

## TalentService 新增方法

```swift
// TalentService.swift

enum TalentResetError: LocalizedError {
    case noInvestedNodes
    case insufficientGold(required: Int, have: Int)

    var errorDescription: String? {
        switch self {
        case .noInvestedNodes:
            return "尚未投入任何天賦"
        case .insufficientGold(let required, let have):
            return "金幣不足（需要 \(required)，擁有 \(have)）"
        }
    }
}

extension TalentService {

    /// 重置所有天賦，退還已投點數，消耗固定金幣
    func resetAllTalents(player: PlayerStateModel) throws {
        let invested = player.investedTalentKeys
        guard !invested.isEmpty else { throw TalentResetError.noInvestedNodes }

        let cost = AppConstants.Talent.resetCost
        guard player.gold >= cost else {
            throw TalentResetError.insufficientGold(required: cost, have: player.gold)
        }

        player.gold                  -= cost
        player.availableTalentPoints += invested.count
        player.investedTalentKeysRaw  = ""

        try context.save()
    }
}
```

---

## CharacterView UI

在被動技能（天賦）Section 底部，已投入節點 > 0 時顯示重置按鈕：

```swift
// talentContent(player:) 末尾
if !player.investedTalentKeys.isEmpty {
    Section {
        Button {
            showResetTalentAlert = true
        } label: {
            Label("重置所有天賦（-\(AppConstants.Talent.resetCost) 金幣）",
                  systemImage: "arrow.uturn.backward")
                .font(.callout)
        }
        .buttonStyle(.bordered)
        .tint(.secondary)
        .disabled(player.gold < AppConstants.Talent.resetCost)
        .frame(maxWidth: .infinity, alignment: .center)
    } footer: {
        if player.gold < AppConstants.Talent.resetCost {
            Text("金幣不足，無法重置")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
```

配合 `.alert` 確認對話框（CharacterView `@State` 新增 `showResetTalentAlert: Bool = false`）：

```swift
.alert("確認重置天賦？", isPresented: $showResetTalentAlert) {
    Button("重置", role: .destructive) {
        guard let p = player else { return }
        try? appState.talentService.resetAllTalents(player: p)
    }
    Button("取消", role: .cancel) {}
} message: {
    Text("將退還所有已投入的天賦點，並解除路線鎖定。\n消耗 \(AppConstants.Talent.resetCost) 金幣，此操作不可復原。")
}
```

---

## 驗收標準

- [ ] 有已投入節點 + 金幣 ≥ 500：按鈕可按 → 確認後清空所有節點，天賦點退還，扣 500 金幣
- [ ] 金幣 < 500：按鈕 disabled，顯示「金幣不足」footer
- [ ] 無已投入節點：重置按鈕不顯示
- [ ] 重置後，被互斥鎖定的路線恢復可投入狀態
- [ ] `xcodebuild` 通過，無新警告
