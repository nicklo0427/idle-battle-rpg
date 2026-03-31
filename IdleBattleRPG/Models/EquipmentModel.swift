// EquipmentModel.swift
// 每件裝備的持久化模型（背包中每件一筆）

import Foundation
import SwiftData

@Model
final class EquipmentModel {

    // MARK: - 欄位

    /// 對應 StaticData/EquipmentDef.swift 中的 key
    var defKey: String

    /// 部位（武器 / 防具 / 飾品）
    var slot: EquipmentSlot

    /// 稀有度（普通 / 精良）
    var rarity: EquipmentRarity

    /// 是否已裝備於英雄身上
    var isEquipped: Bool

    // MARK: - Init

    init(defKey: String, slot: EquipmentSlot, rarity: EquipmentRarity, isEquipped: Bool = false) {
        self.defKey     = defKey
        self.slot       = slot
        self.rarity     = rarity
        self.isEquipped = isEquipped
    }

    // MARK: - 便利計算屬性

    /// 對應的靜態定義（查不到代表 defKey 有誤，回傳 nil）
    var def: EquipmentDef? {
        EquipmentDef.find(key: defKey)
    }

    var displayName: String { def?.name ?? defKey }
    var atkBonus: Int       { def?.atkBonus ?? 0 }
    var defBonus: Int       { def?.defBonus ?? 0 }
    var hpBonus: Int        { def?.hpBonus  ?? 0 }
}
