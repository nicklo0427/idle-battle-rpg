// DungeonProgressionModel.swift
// V2-1 地下城推進狀態模型（SwiftData 單例）
//
// 責任：持有玩家地下城長期推進記錄
//   - 已解鎖的區域 key 集合
//   - 已首通的樓層 key 集合
//
// 所有業務邏輯（解鎖規則、首通判斷）皆在 DungeonProgressionService。
// 此 Model 只存資料，不含任何邏輯。
//
// 儲存格式：JSON-encoded [String]（確保 SwiftData 基本型別相容）
//   例：clearedFloorKeysJSON = "[\"wildland_floor_1\",\"wildland_floor_2\"]"

import Foundation
import SwiftData

@Model
final class DungeonProgressionModel {

    // MARK: - 儲存欄位

    /// 已首通樓層的 key（JSON-encoded [String]）
    /// 首通意義：任務完成時，不論勝負場次，記錄為首次挑戰完成
    var clearedFloorKeysJSON: String

    /// 已解鎖區域的 key（JSON-encoded [String]）
    /// 初始值為第一區 "wildland"，後續由 DungeonProgressionService 在菁英首通時自動擴充
    var unlockedRegionKeysJSON: String

    /// 已擊敗菁英所屬的樓層 key（JSON-encoded [String]）
    /// 儲存格式與 clearedFloorKeysJSON 相同，key 取自 EliteDef.floorKey
    /// V4-2 新增：菁英通關 → 解鎖下一樓層 / 下一區域
    var clearedEliteKeysJSON: String

    // MARK: - Init

    init(
        clearedFloorKeysJSON:   String = "[]",
        unlockedRegionKeysJSON: String = "[\"wildland\"]",
        clearedEliteKeysJSON:   String = "[]"
    ) {
        self.clearedFloorKeysJSON   = clearedFloorKeysJSON
        self.unlockedRegionKeysJSON = unlockedRegionKeysJSON
        self.clearedEliteKeysJSON   = clearedEliteKeysJSON
    }
}
