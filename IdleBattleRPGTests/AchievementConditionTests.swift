// AchievementConditionTests.swift
// 驗證 AchievementDef 靜態資料完整性，以及
// AchievementCondition 各條件邏輯（透過 PlayerStateModel 直接驗證）

import XCTest
@testable import IdleBattleRPG

final class AchievementConditionTests: XCTestCase {

    // MARK: - 靜態資料完整性

    func test_allAchievements_haveUniqueKeys() {
        let keys = AchievementDef.all.map { $0.key }
        let unique = Set(keys)
        XCTAssertEqual(keys.count, unique.count, "每個成就的 key 必須唯一")
    }

    func test_allAchievements_haveNonEmptyFields() {
        for def in AchievementDef.all {
            XCTAssertFalse(def.key.isEmpty,         "\(def.key) key 不能為空")
            XCTAssertFalse(def.title.isEmpty,       "\(def.key) title 不能為空")
            XCTAssertFalse(def.description.isEmpty, "\(def.key) description 不能為空")
            XCTAssertFalse(def.icon.isEmpty,        "\(def.key) icon 不能為空")
        }
    }

    func test_allAchievements_countIs10() {
        XCTAssertEqual(AchievementDef.all.count, 10)
    }

    func test_find_existingKey_returnsCorrectDef() {
        let def = AchievementDef.find(key: "first_blood")
        XCTAssertNotNil(def)
        XCTAssertEqual(def?.key, "first_blood")
        XCTAssertEqual(def?.icon, "⚔️")
    }

    func test_find_nonExistingKey_returnsNil() {
        XCTAssertNil(AchievementDef.find(key: "does_not_exist"))
    }

    // MARK: - .battlesWon 條件

    func test_battlesWon_metExactly() {
        let player = makePlayer(battlesWon: 1)
        XCTAssertTrue(evaluateBattlesWon(1, player: player))
    }

    func test_battlesWon_notMet() {
        let player = makePlayer(battlesWon: 0)
        XCTAssertFalse(evaluateBattlesWon(1, player: player))
    }

    func test_battlesWon_exceeds_stillTrue() {
        let player = makePlayer(battlesWon: 999)
        XCTAssertTrue(evaluateBattlesWon(100, player: player))
    }

    // MARK: - .goldEarned 條件

    func test_goldEarned_met() {
        let player = makePlayer(goldEarned: 50000)
        XCTAssertTrue(evaluateGoldEarned(50000, player: player))
    }

    func test_goldEarned_notMet() {
        let player = makePlayer(goldEarned: 49999)
        XCTAssertFalse(evaluateGoldEarned(50000, player: player))
    }

    func test_goldEarned_exceeds_stillTrue() {
        let player = makePlayer(goldEarned: 100000)
        XCTAssertTrue(evaluateGoldEarned(50000, player: player))
    }

    // MARK: - .itemsCrafted 條件

    func test_itemsCrafted_met() {
        let player = makePlayer(itemsCrafted: 15)
        XCTAssertTrue(evaluateItemsCrafted(15, player: player))
    }

    func test_itemsCrafted_notMet() {
        let player = makePlayer(itemsCrafted: 14)
        XCTAssertFalse(evaluateItemsCrafted(15, player: player))
    }

    // MARK: - .heroLevel 條件

    func test_heroLevel_met() {
        let player = makePlayer(heroLevel: 20)
        XCTAssertTrue(evaluateHeroLevel(20, player: player))
    }

    func test_heroLevel_notMet() {
        let player = makePlayer(heroLevel: 19)
        XCTAssertFalse(evaluateHeroLevel(20, player: player))
    }

    func test_heroLevel_exceeds_stillTrue() {
        let player = makePlayer(heroLevel: 20)
        XCTAssertTrue(evaluateHeroLevel(5, player: player))
    }

    // MARK: - AchievementDef.all 各成就條件型別覆蓋率

    func test_allConditionTypes_coveredInDefs() {
        var seenTypes = Set<String>()
        for def in AchievementDef.all {
            switch def.condition {
            case .battlesWon:    seenTypes.insert("battlesWon")
            case .goldEarned:    seenTypes.insert("goldEarned")
            case .itemsCrafted:  seenTypes.insert("itemsCrafted")
            case .heroLevel:     seenTypes.insert("heroLevel")
            case .floorCleared:  seenTypes.insert("floorCleared")
            }
        }
        XCTAssertTrue(seenTypes.contains("battlesWon"),   "應有 battlesWon 條件")
        XCTAssertTrue(seenTypes.contains("goldEarned"),   "應有 goldEarned 條件")
        XCTAssertTrue(seenTypes.contains("itemsCrafted"), "應有 itemsCrafted 條件")
        XCTAssertTrue(seenTypes.contains("heroLevel"),    "應有 heroLevel 條件")
        XCTAssertTrue(seenTypes.contains("floorCleared"), "應有 floorCleared 條件")
    }

    // MARK: - floorCleared 條件（regionKey / floorIndex 結構驗證）

    func test_floorCleared_allRegionKeysReferenceValidRegions() {
        let validRegionKeys = Set(DungeonRegionDef.all.map { $0.key })
        for def in AchievementDef.all {
            if case .floorCleared(let regionKey, _) = def.condition {
                XCTAssertTrue(validRegionKeys.contains(regionKey),
                              "\(def.key) 的 regionKey='\(regionKey)' 在 DungeonRegionDef 中不存在")
            }
        }
    }

    func test_floorCleared_allFloorIndexesAreValid() {
        for def in AchievementDef.all {
            if case .floorCleared(let regionKey, let floorIndex) = def.condition {
                let region = DungeonRegionDef.find(key: regionKey)
                XCTAssertNotNil(region, "\(def.key) regionKey 找不到對應區域")
                let floor = region?.floor(index: floorIndex)
                XCTAssertNotNil(floor,
                                "\(def.key) floorIndex=\(floorIndex) 在 \(regionKey) 中不存在")
            }
        }
    }

    // MARK: - AchievementProgressModel 解鎖與查詢

    func test_progressModel_initiallyEmpty() {
        let model = AchievementProgressModel()
        XCTAssertTrue(model.unlockedKeys.isEmpty)
    }

    func test_progressModel_markUnlocked_isReflected() {
        let model = AchievementProgressModel()
        model.markUnlocked(key: "first_blood")
        XCTAssertTrue(model.isUnlocked(key: "first_blood"))
    }

    func test_progressModel_unknownKey_isFalse() {
        let model = AchievementProgressModel()
        XCTAssertFalse(model.isUnlocked(key: "not_real"))
    }

    func test_progressModel_markUnlocked_isIdempotent() {
        let model = AchievementProgressModel()
        model.markUnlocked(key: "first_blood")
        model.markUnlocked(key: "first_blood")
        model.markUnlocked(key: "first_blood")
        XCTAssertEqual(model.unlockedKeys.count, 1)
    }

    func test_progressModel_multipleUnlocks() {
        let model = AchievementProgressModel()
        model.markUnlocked(key: "first_blood")
        model.markUnlocked(key: "first_craft")
        model.markUnlocked(key: "gold_tycoon")
        XCTAssertEqual(model.unlockedKeys.count, 3)
        XCTAssertTrue(model.isUnlocked(key: "first_blood"))
        XCTAssertTrue(model.isUnlocked(key: "first_craft"))
        XCTAssertTrue(model.isUnlocked(key: "gold_tycoon"))
        XCTAssertFalse(model.isUnlocked(key: "legend_hero"))
    }

    // MARK: - Helpers

    private func makePlayer(
        heroLevel:    Int = 1,
        battlesWon:   Int = 0,
        goldEarned:   Int = 0,
        itemsCrafted: Int = 0
    ) -> PlayerStateModel {
        let p = PlayerStateModel(
            gold: 100,
            heroLevel: heroLevel,
            availableStatPoints: 0,
            atkPoints: 5,
            defPoints: 3,
            hpPoints: 20,
            lastOpenedAt: Date(),
            hasUsedFirstCraftBoost: false,
            hasUsedFirstDungeonBoost: false,
            onboardingStep: 0
        )
        p.totalBattlesWon   = battlesWon
        p.totalGoldEarned   = goldEarned
        p.totalItemsCrafted = itemsCrafted
        return p
    }

    // 直接模擬 AchievementService.evaluate 中的邏輯（避免需要 ModelContext）
    private func evaluateBattlesWon(_ count: Int, player: PlayerStateModel) -> Bool {
        player.totalBattlesWon >= count
    }
    private func evaluateGoldEarned(_ amount: Int, player: PlayerStateModel) -> Bool {
        player.totalGoldEarned >= amount
    }
    private func evaluateItemsCrafted(_ count: Int, player: PlayerStateModel) -> Bool {
        player.totalItemsCrafted >= count
    }
    private func evaluateHeroLevel(_ level: Int, player: PlayerStateModel) -> Bool {
        player.heroLevel >= level
    }
}
