// NewPlayerFlowView.swift
// V10-1 新玩家流程容器：依序顯示開場敘事 → 英雄命名 → 職業選擇
//
// 由 ContentView 傳入已確認存在的 PlayerStateModel，不自行等待 @Query 載入。
// ContentView 負責在 classKey 設定後切換回主遊戲。

import SwiftUI
import SwiftData

struct NewPlayerFlowView: View {

    let player: PlayerStateModel

    private enum Step { case intro, naming, classSelection }

    @State private var step: Step

    init(player: PlayerStateModel) {
        self.player = player
        // 根據玩家現有狀態決定起始步驟（同步、無 @Query 時序問題）
        _step = State(initialValue: player.hasSeenIntro ? .naming : .intro)
    }

    var body: some View {
        switch step {
        case .intro:
            IntroNarrativeView { self.step = .naming }
        case .naming:
            HeroNameView { self.step = .classSelection }
        case .classSelection:
            ClassSelectionView()
        }
    }
}
