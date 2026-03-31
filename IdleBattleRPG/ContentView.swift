// ContentView.swift
// Phase 1 最小可讀寫驗證畫面
// 目的：確認 SwiftData seeding 正常、四個 Model 可讀可寫
// Phase 4 完成後此檔案將被替換為正式 TabView 介面

import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(\.modelContext) private var context

    @Query private var players:    [PlayerStateModel]
    @Query private var inventories:[MaterialInventoryModel]
    @Query private var equipments: [EquipmentModel]
    @Query private var tasks:      [TaskModel]

    var body: some View {
        NavigationStack {
            List {

                // ── 玩家狀態 ────────────────────────────────────────
                Section("玩家狀態") {
                    if let p = players.first {
                        row("金幣",    "\(p.gold)")
                        row("等級",    "Lv.\(p.heroLevel)")
                        row("ATK 點", "\(p.atkPoints)")
                        row("DEF 點", "\(p.defPoints)")
                        row("HP 點",  "\(p.hpPoints)")
                        row("Onboarding", "\(p.onboardingStep) / 3")
                    } else {
                        Text("⚠️ 尚無玩家資料").foregroundStyle(.red)
                    }
                }

                // ── 素材庫存 ────────────────────────────────────────
                Section("素材庫存") {
                    if let inv = inventories.first {
                        row("🪵 木材",    "\(inv.wood)")
                        row("🪨 礦石",    "\(inv.ore)")
                        row("🐾 獸皮",    "\(inv.hide)")
                        row("💎 魔晶石",  "\(inv.crystalShard)")
                        row("🔮 古代碎片","\(inv.ancientFragment)")
                    } else {
                        Text("⚠️ 尚無素材資料").foregroundStyle(.red)
                    }
                }

                // ── 裝備（背包）────────────────────────────────────
                Section("裝備（\(equipments.count) 件）") {
                    ForEach(equipments) { equip in
                        HStack {
                            Text(equip.slot.icon)
                            Text(equip.displayName)
                            Spacer()
                            Text(equip.rarity.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if equip.isEquipped {
                                Text("已裝備")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    if equipments.isEmpty {
                        Text("⚠️ 尚無裝備資料").foregroundStyle(.red)
                    }
                }

                // ── 任務（TaskModel 寫入測試）──────────────────────
                Section("任務（\(tasks.count) 筆）") {
                    ForEach(tasks) { task in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(task.kind.rawValue) — \(task.actorKey)")
                                .font(.subheadline)
                            Text("結束：\(task.endsAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if tasks.isEmpty {
                        Text("無進行中任務").foregroundStyle(.secondary)
                    }

                    // 寫入測試按鈕
                    Button("➕ 新增測試採集任務") {
                        insertTestGatherTask()
                    }
                }

                // ── 靜態資料快查 ────────────────────────────────────
                Section("靜態資料（不存 DB）") {
                    row("採集地點", "\(GatherLocationDef.all.count) 個")
                    row("鑄造配方", "\(CraftRecipeDef.all.count) 個")
                    row("地下城區域", "\(DungeonAreaDef.all.count) 個")
                    row("裝備定義", "\(EquipmentDef.all.count) 種")
                    row("商人兌換", "\(MerchantTradeDef.all.count) 筆")
                }
            }
            .navigationTitle("Phase 1 驗證")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Helpers

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }

    /// 插入一筆測試採集任務，驗證 TaskModel 可正常寫入
    private func insertTestGatherTask() {
        let now   = Date.now
        let task  = TaskModel(
            kind:         .gather,
            actorKey:     AppConstants.Actor.gatherer1,
            definitionKey: GatherLocationDef.all[0].key,
            startedAt:    now,
            endsAt:       now.addingTimeInterval(
                TimeInterval(GatherLocationDef.all[0].durationSeconds)
            )
        )
        context.insert(task)
        try? context.save()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            PlayerStateModel.self,
            MaterialInventoryModel.self,
            EquipmentModel.self,
            TaskModel.self,
        ], inMemory: true)
}
