// ClassDef.swift
// V6-1 職業靜態定義
//
// 設計原則：
//   - 4 個職業，遊戲開始時一次選擇，不可更換
//   - 各職業提供永久基礎屬性加成
//   - 各職業有 5 個專屬技能（透過 SkillDef.skillKeys 關聯）
//   - 純 Swift struct，不進 SwiftData

import SwiftUI

// MARK: - 職業定義

struct ClassDef {
    let key:                  String     // e.g. "swordsman"
    let name:                 String     // e.g. "劍士"
    let description:          String     // 職業簡介
    let backstory:            String     // 你的過去（V10-1 敘事）
    let skillKeys:            [String]   // 此職業專屬的 5 個技能 key（依解鎖等級排序）
    let starterEquipmentKeys: [String]   // 初始裝備 key 列表（V10-1）
    let baseATKBonus:         Int
    let baseDEFBonus:         Int
    let baseHPBonus:          Int
    let baseAGIBonus:         Int
    let baseDEXBonus:         Int
}

// MARK: - 靜態資料

extension ClassDef {

    static let all: [ClassDef] = [swordsman, archer, mage, paladin]

    static func find(key: String) -> ClassDef? {
        all.first { $0.key == key }
    }
}

// MARK: - UI 輔助

extension ClassDef {

    var iconName: String {
        switch key {
        case "swordsman": return "figure.fencing"
        case "archer":    return "arrow.up.right"
        case "mage":      return "flame.fill"
        case "paladin":   return "shield.fill"
        default:          return "person.fill"
        }
    }

    var themeColor: Color {
        switch key {
        case "swordsman": return .red
        case "archer":    return .green
        case "mage":      return .purple
        case "paladin":   return .blue
        default:          return .gray
        }
    }

    /// 職業加成對戰力的估算影響（ATK×2 + DEF×1.5 + HP×1；AGI/DEX 不計入戰力）
    var estimatedPowerBonus: Int {
        Int(Double(baseATKBonus) * 2.0 + Double(baseDEFBonus) * 1.5) + baseHPBonus
    }

    /// 基礎加成摘要文字，e.g. "ATK +5"
    var bonusSummary: String {
        var parts: [String] = []
        if baseATKBonus > 0 { parts.append("ATK +\(baseATKBonus)") }
        if baseDEFBonus > 0 { parts.append("DEF +\(baseDEFBonus)") }
        if baseHPBonus  > 0 { parts.append("HP +\(baseHPBonus)") }
        if baseAGIBonus > 0 { parts.append("AGI +\(baseAGIBonus)") }
        if baseDEXBonus > 0 { parts.append("DEX +\(baseDEXBonus)") }
        return parts.joined(separator: "  ")
    }
}

// MARK: - 職業資料

extension ClassDef {

    /// 劍士 — ATK 專精，以力破法的前線鬥士
    static let swordsman = ClassDef(
        key:                  "swordsman",
        name:                 "劍士",
        description:          "以力破法，一刀定勝負的前線鬥士。",
        backstory:            "你是前線衛隊的老兵，一柄長劍百戰不敗。那次任務孤身深入廢墟追蹤魔物群，以一擋百，力竭倒下。身體仍記得一切——手握劍柄的瞬間，熟悉的重量回來了。",
        skillKeys:            ["sw_slash_boost", "sw_iron_will", "sw_war_cry", "sw_fierce_blow", "sw_peerless"],
        starterEquipmentKeys: ["rusty_sword", "rusty_parry_blade"],
        baseATKBonus:         5,
        baseDEFBonus:         0,
        baseHPBonus:          0,
        baseAGIBonus:         0,
        baseDEXBonus:         0
    )

    /// 弓手 — AGI/DEX 專精，疾如風影的速攻遊俠
    static let archer = ClassDef(
        key:                  "archer",
        name:                 "弓手",
        description:          "疾如風影，先手制人的速攻遊俠。",
        backstory:            "你是遊走四方的賞金獵人，沒有歸屬，靠著長弓和快腿討生活。廢墟中那場遭遇讓你栽了跟頭，對手不按常理出牌。這次，你會記取教訓。",
        skillKeys:            ["ar_swift_step", "ar_eagle_eye", "ar_wind_walk", "ar_sniper", "ar_phantom_step"],
        starterEquipmentKeys: ["rusty_bow", "rusty_quiver"],
        baseATKBonus:         0,
        baseDEFBonus:         0,
        baseHPBonus:          0,
        baseAGIBonus:         3,
        baseDEXBonus:         2
    )

    /// 法師 — ATK/AGI 平衡，詭謀多算的奧術操縱者
    static let mage = ClassDef(
        key:                  "mage",
        name:                 "法師",
        description:          "詭謀多算，以術輔攻的奧術操縱者。",
        backstory:            "你是學院出身的術士，因鑽研禁忌魔法遭驅逐。廢墟裡封印的古代知識讓你如獲至寶，卻也讓你付出代價。法力仍在，只需時間重新掌控。",
        skillKeys:            ["mg_magic_bolt", "mg_arcane_shield", "mg_mana_surge", "mg_time_warp", "mg_arcane_mastery"],
        starterEquipmentKeys: ["rusty_wand", "rusty_grimoire"],
        baseATKBonus:         3,
        baseDEFBonus:         0,
        baseHPBonus:          0,
        baseAGIBonus:         2,
        baseDEXBonus:         0
    )

    /// 聖騎士 — DEF/HP 專精，堅不可摧的不滅衛士
    static let paladin = ClassDef(
        key:                  "paladin",
        name:                 "聖騎士",
        description:          "堅不可摧，以盾護身的不滅衛士。",
        backstory:            "你曾是聖堂的護衛騎士，誓言守護弱者。那場戰鬥中你以血肉之軀擋住同伴退路，卻讓自己陷入絕境。聖光仍在血脈中流淌——不是為了榮耀，而是一個承諾。",
        skillKeys:            ["pl_iron_guard", "pl_healing_aura", "pl_shield_wall", "pl_blessed_armor", "pl_aegis"],
        starterEquipmentKeys: ["rusty_hammer", "rusty_shield"],
        baseATKBonus:         0,
        baseDEFBonus:         4,
        baseHPBonus:          15,
        baseAGIBonus:         0,
        baseDEXBonus:         0
    )
}
