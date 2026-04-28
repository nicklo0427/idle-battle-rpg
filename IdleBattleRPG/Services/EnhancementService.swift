// EnhancementService.swift
// 裝備強化與拆解服務
//
// 責任：
//   enhance(equipment:player:)    — 驗證 + 扣金幣 + 遞增強化等級
//   disassemble(equipment:player:) — 驗證 + 入帳退還金幣 + 刪除裝備
//
// 設計原則：
//   - 扣除與寫入在同一 context.save() 內（原子）
//   - 資源不足 / 條件不符時回傳 .failure，不寫入任何資料
//   - 強化金幣消耗不於拆解時退還（規格設計）

import Foundation
import SwiftData

// MARK: - 錯誤類型

enum EnhanceError: Error {
    case alreadyMaxLevel        // 已達最高強化等級
    case insufficientGold       // 金幣不足

    var message: String {
        switch self {
        case .alreadyMaxLevel:   return "已達最高強化等級 +\(EnhancementDef.maxLevel)"
        case .insufficientGold:  return "金幣不足"
        }
    }
}

enum DisassembleError: Error {
    case cannotDisassemble      // 不可拆解（初始裝備或查無規則）
    case isEquipped             // 裝備中，不可拆解

    var message: String {
        switch self {
        case .cannotDisassemble: return "此裝備不可拆解"
        case .isEquipped:        return "請先卸除裝備再拆解"
        }
    }
}

// MARK: - EnhancementService

struct EnhancementService {

    let context: ModelContext

    // MARK: - 強化

    /// 強化一件裝備：扣金幣、遞增 enhancementLevel。
    /// 已達 +8 或金幣不足時回傳 .failure，不寫入資料。
    @discardableResult
    func enhance(equipment: EquipmentModel, player: PlayerStateModel) -> Result<Void, EnhanceError> {
        guard equipment.enhancementLevel < EnhancementDef.maxLevel else {
            return .failure(.alreadyMaxLevel)
        }
        guard let cost = EnhancementDef.goldCost(fromLevel: equipment.enhancementLevel) else {
            return .failure(.alreadyMaxLevel)
        }
        guard player.gold >= cost else {
            return .failure(.insufficientGold)
        }

        player.gold -= cost
        equipment.enhancementLevel += 1
        save()

        print("[EnhancementService] 強化 \(equipment.displayName)（費用 \(cost) 金）")
        return .success(())
    }

    // MARK: - 拆解

    /// 拆解一件未裝備的裝備：入帳退還金幣、刪除裝備。
    /// 已裝備或不可拆解時回傳 .failure，不寫入資料。
    @discardableResult
    func disassemble(equipment: EquipmentModel, player: PlayerStateModel) -> Result<Void, DisassembleError> {
        guard !equipment.isEquipped else {
            return .failure(.isEquipped)
        }
        guard let refund = EnhancementDef.disassembleRefund(defKey: equipment.defKey) else {
            return .failure(.cannotDisassemble)
        }

        player.gold += refund
        context.delete(equipment)
        save()

        print("[EnhancementService] 拆解 \(equipment.defKey)，退還 \(refund) 金")
        return .success(())
    }

    // MARK: - 便利查詢（供 UI 預先判斷）

    /// 強化下一等的金幣成本；已滿級時回傳 nil
    func nextEnhanceCost(for equipment: EquipmentModel) -> Int? {
        guard equipment.enhancementLevel < EnhancementDef.maxLevel else { return nil }
        return EnhancementDef.goldCost(fromLevel: equipment.enhancementLevel)
    }

    /// 拆解退還金幣；不可拆解時回傳 nil
    func disassembleRefund(for equipment: EquipmentModel) -> Int? {
        EnhancementDef.disassembleRefund(defKey: equipment.defKey)
    }

    // MARK: - Private

    private func save() {
        try? context.save()
    }
}
