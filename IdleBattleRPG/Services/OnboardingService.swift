// OnboardingService.swift
// 新手引導流程協調：文案、差額補給、步驟推進

import Foundation
import SwiftData

struct OnboardingStepInfo {
    let hint: [TutorialTextRun]
    let flavor: String
}

enum OnboardingTutorialKey {
    static let gatherWood   = "tutorial_gather"
    static let starterWeapon = "tutorial_craft"
    static let armorMaterials = "tutorial_explore"
    static let starterArmor = "tutorial_armor"
    static let firstDungeon = "tutorial_first_dungeon"
    static let farmWheat    = "tutorial_farm_wheat"
    static let fishStew     = "tutorial_cuisine_fish_stew"
    static let smallPotion  = "tutorial_alchemy_small_potion"
    static let buffedRun    = "tutorial_buffed_dungeon"
}

struct OnboardingService {

    static let completedStep = 23
    static let totalSteps = 23
    static let nonCombatTutorialTaskDurationSeconds = 10
    static let combatTutorialTaskDurationSeconds = 2

    let context: ModelContext

    // MARK: - Step Info

    static func stepInfo(step: Int) -> OnboardingStepInfo? {
        switch step {
        case 0:
            return .init(hint: [
                .plain("在"), .location("基地的採集者營地"), .plain("找到"),
                .action("伐木工阿森"), .plain("，派他採集"),
                .material("木材"), .plain("，準備打造"), .equipment("初始武器"),
            ], flavor: "要塞破舊，需要新的裝備來重整。")
        case 1:
            return .init(hint: [
                .plain("在"), .location("基地"), .plain("等待"),
                .action("伐木工阿森"), .plain("完成"), .action("採集"), .plain("。"),
            ], flavor: "斧頭聲迴盪在林間，木材一根根累積。")
        case 2:
            return .init(hint: [
                .plain("在"), .location("基地的生產者小屋"), .plain("找到"),
                .action("鑄造師老鐵"), .plain("，打造你的"),
                .equipment("初始武器"),
            ], flavor: "原料到手，是時候打出第一把武器了。")
        case 3:
            return .init(hint: [
                .plain("到"), .action("角色"), .plain("頁打開"),
                .equipment("裝備欄"), .plain("，從"), .equipment("背包"),
                .plain("選擇並裝備"), .equipment("初始武器"),
            ], flavor: "鐵鎚聲落定，武器剛淬煉完工，該親手把它裝上了。")
        case 4:
            return .init(hint: [
                .plain("到"), .action("冒險"), .plain("頁進入"),
                .location("穀倉前道"), .plain("，"),
                .action("挑戰穀道裂爪衛"), .plain("取得"), .equipment("防具配方"), .plain("。"),
            ], flavor: "手握武器，準備第一場真正的戰鬥。")
        case 5:
            return .init(hint: [
                .plain("在"), .location("基地的生產者小屋"), .plain("找到"),
                .action("裁縫師阿針"), .plain("，確認第一件"),
                .equipment("防具"), .plain("需要的"), .material("防具素材"), .plain("。"),
            ], flavor: "有了武器，接下來要學會如何護住自己。")
        case 6:
            return .init(hint: [
                .plain("到"), .action("冒險"), .plain("頁前往"),
                .location("金穗之野"), .plain("，"), .action("探索"),
                .plain("取得"), .material("防具素材"), .plain("。"),
            ], flavor: "荒野中的獸皮正是打造護甲的材料。")
        case 7:
            return .init(hint: [
                .plain("回到"), .location("基地的生產者小屋"), .plain("找"),
                .action("裁縫師阿針"), .plain("，用"), .material("素材"),
                .plain("完成"), .equipment("防具"), .plain("製作。"),
            ], flavor: "皮革的氣味充滿小屋，護甲即將成形。")
        case 8:
            return .init(hint: [
                .plain("新做好的"), .equipment("防具"), .plain("已放進"),
                .equipment("背包"), .plain("。到"), .equipment("裝備欄"),
                .plain("點開"), .equipment("防具欄位"), .plain("，從"),
                .equipment("背包"), .plain("選擇這件"), .equipment("防具"),
                .plain("親手穿上。"),
            ], flavor: "護甲已放進背包，真正穿上才算準備好。")
        case 9:
            return .init(hint: [
                .plain("到"), .action("冒險"), .plain("頁進入"),
                .location("穀倉前道"), .plain("，按"),
                .action("出發"), .plain("開始第一次正式出征。"),
            ], flavor: "裝備齊了，該讓英雄走一趟真正的路。")
        case 10:
            return .init(hint: [
                .plain("在"), .action("冒險"), .plain("頁查看"),
                .action("戰鬥過程"), .plain("並"), .action("收下獎勵"),
                .plain("，解鎖"), .action("升級與技能"), .plain("。"),
            ], flavor: "戰鬥經驗會把英雄推向第一個成長節點。")
        case 11:
            return .init(hint: [
                .plain("到"), .action("角色"), .plain("頁分配"),
                .action("屬性點"), .plain("，再按"), .action("確認加點"), .plain("。"),
            ], flavor: "力量、護甲、速度，先選一個你想強化的方向。")
        case 12:
            return .init(hint: [
                .plain("在"), .action("角色"), .plain("頁切到"),
                .action("技能"), .plain("，"), .action("升階"),
                .plain("或"), .action("配備"), .plain("第一個主動技能。"),
            ], flavor: "技能會在出征戰鬥中自動施放。")
        case 13:
            return .init(hint: [
                .plain("在"), .action("角色"), .plain("頁切到"),
                .action("天賦樹"), .plain("，投入第一個"),
                .action("天賦點"), .plain("。"),
            ], flavor: "天賦是長期成長路線，先點出第一步。")
        case 14:
            return .init(hint: [
                .plain("在"), .action("角色"), .plain("頁回到"),
                .equipment("裝備欄"), .plain("，把"), .equipment("武器"),
                .plain("強化到"), .equipment("+1"), .plain("。"),
            ], flavor: "一點強化，就能讓早期戰鬥舒服很多。")
        case 15:
            return .init(hint: [
                .plain("在"), .location("基地的商店"), .plain("找到"),
                .action("商人老錢"), .plain("，購買"),
                .material("小麥種子"), .plain("。"),
            ], flavor: "農田需要種子，市集是最穩定的補給點。")
        case 16:
            return .init(hint: [
                .plain("在"), .location("基地的採集者營地"), .plain("找到"),
                .action("農夫老禾"), .plain("，在"), .action("農田 1"),
                .plain("種下"), .material("小麥種子"), .plain("。"),
            ], flavor: "農田會把種子變成料理與藥水需要的作物。")
        case 17:
            return .init(hint: [
                .plain("在"), .location("基地的生產者小屋"), .plain("找到"),
                .action("廚師阿灶"), .plain("，製作第一份"),
                .equipment("魚肉燉鍋"), .plain("。"),
            ], flavor: "料理可在出征前攜帶，提供一段時間的屬性加成。")
        case 18:
            return .init(hint: [
                .plain("在"), .location("基地的生產者小屋"), .plain("找到"),
                .action("藥師白芷"), .plain("，製作第一瓶"),
                .equipment("小型藥水"), .plain("。"),
            ], flavor: "藥水會在戰鬥危急時自動救場。")
        case 19:
            return .init(hint: [
                .plain("回到"), .action("冒險"), .plain("頁打開"),
                .location("穀倉前道"), .plain("，攜帶"),
                .equipment("料理"), .plain("與"), .equipment("藥水"),
                .plain("再"), .action("出征"), .plain("一次。"),
            ], flavor: "把補給帶上戰場，完整循環就接起來了。")
        case 20:
            return .init(hint: [
                .plain("回到"), .location("基地的採集者營地"), .plain("找"),
                .action("伐木工阿森"), .plain("，開啟"),
                .action("狀態及養成"), .plain("升到"), .action("T1"), .plain("。"),
            ], flavor: "NPC 也能養成，升級後會獲得技能點。")
        case 21:
            return .init(hint: [
                .plain("在"), .action("伐木工阿森"), .plain("的"),
                .action("技能"), .plain("頁投入"), .action("砍伐熟練"), .plain("。"),
            ], flavor: "技能點會讓採集產出更穩，之後也能套用到其他 NPC。")
        case 22:
            return .init(hint: [
                .plain("最後到"), .action("角色"), .plain("頁切到"),
                .action("成就"), .plain("，查看已解鎖的"), .action("成就"), .plain("。"),
            ], flavor: "到這裡，新手訓練就能正式收尾。")
        default:
            return nil
        }
    }

    static func targetActor(for step: Int) -> String? {
        switch step {
        case 0: return AppConstants.Actor.gatherer1
        case 2: return AppConstants.Actor.blacksmith
        case 5, 7: return AppConstants.Actor.tailor
        case 15: return "merchant"
        case 16: return "farmer"
        case 17: return AppConstants.Actor.chef
        case 18: return AppConstants.Actor.pharmacist
        case 20, 21: return AppConstants.Actor.gatherer1
        default: return nil
        }
    }

    // MARK: - Step Progression

    func advance(player: PlayerStateModel?, from expectedStep: Int, to nextStep: Int) {
        guard let player, player.onboardingStep == expectedStep else { return }
        player.onboardingStep = nextStep
        try? context.save()
    }

    func finish(player: PlayerStateModel?) {
        guard let player, player.onboardingStep == 22 else { return }
        player.onboardingStep = Self.completedStep
        try? context.save()
    }

    func prepareForCurrentStep() {
        guard let player = fetchPlayer(), player.onboardingStep < Self.completedStep else { return }
        prepareForStep(player.onboardingStep, player: player)
    }

    func prepareForStep(_ step: Int, player: PlayerStateModel) {
        let supplyKey = "step_\(step)"
        guard !player.hasReceivedOnboardingSupply(supplyKey) else { return }

        let inventory = fetchInventory()
        switch step {
        case 14:
            ensureGold(100, player: player)
        case 15:
            ensureGold(80, player: player)
        case 16:
            guard let inventory else { return }
            ensureMaterial(.wheatSeed, atLeast: 1, inventory: inventory)
        case 17:
            guard let inventory else { return }
            ensureGold(40, player: player)
            ensureMaterial(.freshFish, atLeast: 5, inventory: inventory)
            ensureMaterial(.herb, atLeast: 3, inventory: inventory)
        case 18:
            guard let inventory else { return }
            ensureGold(50, player: player)
            ensureMaterial(.wheat, atLeast: 5, inventory: inventory)
            ensureMaterial(.vegetable, atLeast: 3, inventory: inventory)
        case 20:
            guard let inventory else { return }
            ensureGold(300, player: player)
            ensureHeroExp(60, player: player)
            ensureMaterial(.wood, atLeast: 10, inventory: inventory)
        default:
            return
        }
        player.markOnboardingSupplyReceived(supplyKey)
        try? context.save()
    }

    func ensureHeroLevelAtLeast3(player: PlayerStateModel) {
        while player.heroLevel < 3 {
            let nextLevel = player.heroLevel + 1
            guard let required = AppConstants.ExpThreshold.required(toLevel: nextLevel) else { break }
            ensureHeroExp(required, player: player)
            _ = CharacterProgressionService(context: context).levelUp(player: player)
        }
        try? context.save()
    }

    // MARK: - Private

    private func fetchPlayer() -> PlayerStateModel? {
        (try? context.fetch(FetchDescriptor<PlayerStateModel>()))?.first
    }

    private func fetchInventory() -> MaterialInventoryModel? {
        (try? context.fetch(FetchDescriptor<MaterialInventoryModel>()))?.first
    }

    private func ensureGold(_ amount: Int, player: PlayerStateModel) {
        if player.gold < amount { player.gold = amount }
    }

    private func ensureHeroExp(_ amount: Int, player: PlayerStateModel) {
        if player.heroExp < amount { player.heroExp = amount }
    }

    private func ensureMaterial(_ material: MaterialType, atLeast amount: Int, inventory: MaterialInventoryModel) {
        let current = inventory.amount(of: material)
        guard current < amount else { return }
        inventory.add(amount - current, of: material)
    }
}
