# V6-2 Ticket 03：TalentService

**狀態：** 🔲 待實作
**版本：** V6-2
**依賴：** T01、T02

---

## 說明

新增 `TalentService.swift`，封裝天賦點投入的業務邏輯與驗證，遵循專案 Service 層規範：接受 `ModelContext` 建構子注入，負責寫入 SwiftData，不管理 UI 狀態。

---

## TalentService 設計

```swift
// IdleBattleRPG/Services/TalentService.swift

import Foundation
import SwiftData

struct TalentService {
    let context: ModelContext

    // MARK: - 查詢

    /// 玩家已投入的所有天賦節點
    func investedNodes(for player: PlayerStateModel) -> [TalentNodeDef] {
        player.investedTalentKeys.compactMap { TalentNodeDef.find(key: $0) }
    }

    /// 是否可以投入指定天賦節點
    func canInvest(nodeKey: String, for player: PlayerStateModel) -> Bool {
        guard player.availableTalentPoints > 0 else { return false }
        guard !player.investedTalentKeys.contains(nodeKey) else { return false }
        guard let node = TalentNodeDef.find(key: nodeKey) else { return false }

        // 第一個節點（nodeIndex == 0）直接可投
        if node.nodeIndex == 0 { return true }

        // 前一節點必須已投入
        guard let route = TalentRouteDef.find(key: node.routeKey) else { return false }
        let prevNode = route.nodes.first { $0.nodeIndex == node.nodeIndex - 1 }
        guard let prev = prevNode else { return false }
        return player.investedTalentKeys.contains(prev.key)
    }

    // MARK: - 寫入

    /// 投入一個天賦點
    /// - Throws: TalentError
    func investPoint(nodeKey: String, for player: PlayerStateModel) throws {
        guard player.availableTalentPoints > 0 else {
            throw TalentError.noPointsAvailable
        }
        guard !player.investedTalentKeys.contains(nodeKey) else {
            throw TalentError.alreadyInvested
        }
        guard let node = TalentNodeDef.find(key: nodeKey) else {
            throw TalentError.nodeNotFound
        }
        if node.nodeIndex > 0 {
            guard let route = TalentRouteDef.find(key: node.routeKey) else {
                throw TalentError.nodeNotFound
            }
            let prevNode = route.nodes.first { $0.nodeIndex == node.nodeIndex - 1 }
            guard let prev = prevNode,
                  player.investedTalentKeys.contains(prev.key) else {
                throw TalentError.previousNodeNotInvested
            }
        }

        // 寫入
        player.availableTalentPoints -= 1
        let updated = (player.investedTalentKeys + [nodeKey]).joined(separator: ",")
        player.investedTalentKeysRaw = updated

        try context.save()
    }
}

// MARK: - 錯誤型別

enum TalentError: LocalizedError {
    case noPointsAvailable
    case alreadyInvested
    case nodeNotFound
    case previousNodeNotInvested

    var errorDescription: String? {
        switch self {
        case .noPointsAvailable:       return "沒有可用的天賦點"
        case .alreadyInvested:         return "此天賦節點已投入"
        case .nodeNotFound:            return "找不到天賦節點"
        case .previousNodeNotInvested: return "需先解鎖前一個節點"
        }
    }
}
```

---

## AppState 整合

在 `AppState` 中新增 `TalentService`（與其他 Services 相同的建構子注入方式）：

```swift
// AppState.swift
let talentService: TalentService

// 初始化（在 init(context:) 或建立位置）
self.talentService = TalentService(context: context)
```

---

## 實作位置

- 新建：`IdleBattleRPG/Services/TalentService.swift`
- 修改：`AppState.swift`（新增 `talentService` 屬性）

---

## 驗收標準

- [ ] `canInvest` 對第一個節點（nodeIndex=0）在有點數時回傳 `true`
- [ ] `canInvest` 對第二個節點（nodeIndex=1）在前一節點未投入時回傳 `false`
- [ ] `investPoint` 成功時 `availableTalentPoints` 減 1，`investedTalentKeysRaw` 包含新 key
- [ ] `investPoint` 在無點數時 throw `noPointsAvailable`
- [ ] `investPoint` 在重複投入時 throw `alreadyInvested`
- [ ] `xcodebuild` 通過
