// SkillUpgradeService.swift
// V6-2 T09 技能升階業務邏輯

import Foundation
import SwiftData

struct SkillUpgradeService {
    let context: ModelContext

    // MARK: - 查詢

    func canUpgrade(skillKey: String, for player: PlayerStateModel) -> Bool {
        guard player.availableSkillPoints > 0 else { return false }
        guard let skill = SkillDef.find(key: skillKey) else { return false }
        return player.level(of: skillKey) < skill.maxLevel
    }

    // MARK: - 寫入

    func upgradeSkill(skillKey: String, for player: PlayerStateModel) throws {
        guard player.availableSkillPoints > 0 else {
            throw SkillUpgradeError.noPointsAvailable
        }
        guard let skill = SkillDef.find(key: skillKey) else {
            throw SkillUpgradeError.skillNotFound
        }
        let current = player.level(of: skillKey)
        guard current < skill.maxLevel else {
            throw SkillUpgradeError.maxLevelReached
        }

        player.availableSkillPoints -= 1
        player.setLevel(current + 1, of: skillKey)

        try context.save()
    }
}

// MARK: - 錯誤型別

enum SkillUpgradeError: LocalizedError {
    case noPointsAvailable
    case skillNotFound
    case maxLevelReached

    var errorDescription: String? {
        switch self {
        case .noPointsAvailable: return "沒有可用的技能點"
        case .skillNotFound:     return "找不到技能"
        case .maxLevelReached:   return "此技能已達最高等級"
        }
    }
}
