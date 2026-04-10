// AchievementProgressModel.swift
// V4-4 成就系統：成就進度持久化模型（SwiftData 單例）
//
// 設計：與 DungeonProgressionModel 相同模式
//   - 單例：App 中只存一筆
//   - unlockedAchievementKeysJSON：JSON-encoded [String]，存已解鎖的成就 key
//   - 業務邏輯（條件評估）皆在 AchievementService，此 Model 只存資料

import Foundation
import SwiftData

@Model
final class AchievementProgressModel {

    // MARK: - 儲存欄位

    /// 已解鎖成就的 key（JSON-encoded [String]）
    /// 例："[\"first_blood\",\"first_craft\"]"
    var unlockedAchievementKeysJSON: String

    // MARK: - Init

    init(unlockedAchievementKeysJSON: String = "[]") {
        self.unlockedAchievementKeysJSON = unlockedAchievementKeysJSON
    }

    // MARK: - 便利讀取

    /// 已解鎖成就 key 的集合（decoded on the fly）
    var unlockedKeys: Set<String> {
        guard let data = unlockedAchievementKeysJSON.data(using: .utf8),
              let keys = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(keys)
    }

    func isUnlocked(key: String) -> Bool {
        unlockedKeys.contains(key)
    }

    /// 標記指定成就為已解鎖（冪等）
    func markUnlocked(key: String) {
        var keys = unlockedKeys
        guard !keys.contains(key) else { return }
        keys.insert(key)
        let sorted = keys.sorted()
        if let data = try? JSONEncoder().encode(sorted),
           let str  = String(data: data, encoding: .utf8) {
            unlockedAchievementKeysJSON = str
        }
    }
}
