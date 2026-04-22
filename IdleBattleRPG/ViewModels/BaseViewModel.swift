// BaseViewModel.swift
// 基地頁面的展示協調 ViewModel
//
// 責任：
//   - 從 View 傳入的 @Query 結果中，提取基地頁所需的摘要資訊。
//   - 提供 NPC 狀態查詢（閒置 / 進行中）。
//   - 提供採集 / 鑄造任務建立入口（委派給 TaskCreationService）。
//   - 不查詢 SwiftData，不寫入，純粹做資料轉換與業務協調。
//
// Phase 6 補充：NPC 狀態查詢、canAffordRecipe、任務建立委派

import Foundation
import SwiftData

@Observable
final class BaseViewModel {

    // MARK: - 任務數量摘要（從 View 的 @Query 結果計算）

    func gatheringCount(from tasks: [TaskModel]) -> Int {
        tasks.filter { $0.kind == .gather && $0.status == .inProgress }.count
    }

    func craftingCount(from tasks: [TaskModel]) -> Int {
        tasks.filter { $0.kind == .craft && $0.status == .inProgress }.count
    }

    func dungeonCount(from tasks: [TaskModel]) -> Int {
        tasks.filter { $0.kind == .dungeon && $0.status == .inProgress }.count
    }

    func completedCount(from tasks: [TaskModel]) -> Int {
        tasks.filter { $0.status == .completed }.count
    }

    // MARK: - NPC 狀態查詢

    /// 指定採集者的進行中任務（nil = 閒置）
    func gatherTaskForActor(_ actorKey: String, from tasks: [TaskModel]) -> TaskModel? {
        tasks.first { $0.actorKey == actorKey && $0.kind == .gather && $0.status == .inProgress }
    }

    /// 鑄造師的進行中任務（nil = 閒置）
    func craftTask(from tasks: [TaskModel]) -> TaskModel? {
        tasks.first { $0.actorKey == AppConstants.Actor.blacksmith && $0.status == .inProgress }
    }

    /// 廚師的進行中任務（nil = 閒置）
    func cuisineTask(from tasks: [TaskModel]) -> TaskModel? {
        tasks.first { $0.actorKey == AppConstants.Actor.chef && $0.status == .inProgress }
    }

    /// 玩家目前是否可以負擔指定料理（素材 + 金幣都足夠）
    func canAffordCuisine(
        _ cuisine: CuisineDef,
        player: PlayerStateModel?,
        inventory: MaterialInventoryModel?
    ) -> Bool {
        guard let player, let inventory else { return false }
        guard player.gold >= cuisine.goldCost else { return false }
        return cuisine.ingredients.allSatisfy { (material, amount) in
            inventory.amount(of: material) >= amount
        }
    }

    /// 玩家目前是否可以負擔指定配方（素材 + 金幣都足夠）
    func canAffordRecipe(
        _ recipe: CraftRecipeDef,
        player: PlayerStateModel?,
        inventory: MaterialInventoryModel?
    ) -> Bool {
        guard let player, let inventory else { return false }
        guard player.gold >= recipe.goldCost else { return false }
        return recipe.requiredMaterials.allSatisfy { req in
            inventory.amount(of: req.material) >= req.amount
        }
    }

    // MARK: - 任務建立委派（View 傳入 context，ViewModel 建 Service 執行）

    /// 建立採集任務
    @discardableResult
    func startGatherTask(
        actorKey: String,
        locationKey: String,
        durationSeconds: Int,
        context: ModelContext
    ) -> Result<Void, TaskCreationError> {
        do {
            try TaskCreationService(context: context)
                .createGatherTask(actorKey: actorKey, locationKey: locationKey, durationSeconds: durationSeconds)
            return .success(())
        } catch let e as TaskCreationError {
            return .failure(e)
        } catch {
            return .failure(.locationNotFound("unknown"))
        }
    }

    /// 採集者技能投點，回傳錯誤訊息（nil = 成功）
    @discardableResult
    func investGathererSkillPoint(
        nodeKey:  String,
        actorKey: String,
        player:   PlayerStateModel,
        context:  ModelContext
    ) -> String? {
        do {
            try GathererSkillService(context: context)
                .investPoint(nodeKey: nodeKey, actorKey: actorKey, player: player)
            return nil
        } catch {
            return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Onboarding 步驟推進

    /// 若 player.onboardingStep == expectedStep，推進到下一步並儲存。
    /// 在「知道了」按鈕或相關操作完成後呼叫。
    func advanceOnboarding(
        expectedStep: Int,
        player: PlayerStateModel,
        context: ModelContext
    ) {
        guard player.onboardingStep == expectedStep else { return }
        player.onboardingStep += 1
        try? context.save()
    }

    /// 建立鑄造任務
    @discardableResult
    func startCraftTask(
        recipeKey: String,
        context: ModelContext
    ) -> Result<Void, TaskCreationError> {
        do {
            try TaskCreationService(context: context).createCraftTask(recipeKey: recipeKey)
            return .success(())
        } catch let e as TaskCreationError {
            return .failure(e)
        } catch {
            return .failure(.recipeNotFound("unknown"))
        }
    }

    /// 建立料理任務（V7-3）
    @discardableResult
    func startCuisineTask(
        recipeKey: String,
        context: ModelContext
    ) -> Result<Void, TaskCreationError> {
        do {
            try TaskCreationService(context: context).createCuisineTask(recipeKey: recipeKey)
            return .success(())
        } catch let e as TaskCreationError {
            return .failure(e)
        } catch {
            return .failure(.recipeNotFound("unknown"))
        }
    }
}
