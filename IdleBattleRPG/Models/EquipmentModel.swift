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

    /// V2-1 Boss 武器浮動 ATK；nil = 使用 EquipmentDef.atkBonus 固定值
    var rolledAtk: Int?

    /// V2-2 強化等級；0 = 未強化，1–5 = 強化等級
    var enhancementLevel: Int

    // MARK: - Init

    init(
        defKey: String, slot: EquipmentSlot, rarity: EquipmentRarity,
        isEquipped: Bool = false, rolledAtk: Int? = nil,
        enhancementLevel: Int = 0
    ) {
        self.defKey            = defKey
        self.slot              = slot
        self.rarity            = rarity
        self.isEquipped        = isEquipped
        self.rolledAtk         = rolledAtk
        self.enhancementLevel  = enhancementLevel
    }

    // MARK: - 便利計算屬性

    /// 對應的靜態定義（查不到代表 defKey 有誤，回傳 nil）
    var def: EquipmentDef? {
        EquipmentDef.find(key: defKey)
    }

    /// 裝備名稱；強化等級 > 0 時加上 +N 後綴
    var displayName: String {
        let base = def?.name ?? defKey
        return enhancementLevel > 0 ? "\(base) +\(enhancementLevel)" : base
    }

    /// ATK 加成 = 基礎（rolledAtk 優先）+ 強化加成
    var atkBonus: Int {
        let base  = rolledAtk ?? def?.atkBonus ?? 0
        let bonus = EnhancementDef.bonus(for: slot)?.atkPerLevel ?? 0
        return base + bonus * enhancementLevel
    }

    /// DEF 加成 = 基礎 + 強化加成
    var defBonus: Int {
        let base  = def?.defBonus ?? 0
        let bonus = EnhancementDef.bonus(for: slot)?.defPerLevel ?? 0
        return base + bonus * enhancementLevel
    }

    /// HP 加成 = 基礎 + 強化加成
    var hpBonus: Int {
        let base  = def?.hpBonus ?? 0
        let bonus = EnhancementDef.bonus(for: slot)?.hpPerLevel ?? 0
        return base + bonus * enhancementLevel
    }

    /// 是否為 Boss 武器浮動版本（有 rolledAtk）
    var isRolledBossWeapon: Bool { rolledAtk != nil }

    // MARK: - 換裝差值計算用（含強化加成，同 atkBonus/defBonus/hpBonus）

    var totalAtk: Int { atkBonus }
    var totalDef: Int { defBonus }
    var totalHp:  Int { hpBonus }
}
