// HeroNameView.swift
// V10-1 英雄命名畫面：介於開場敘事與職業選擇之間

import SwiftUI
import SwiftData

struct HeroNameView: View {

    @Environment(\.modelContext) private var context
    @Query private var players: [PlayerStateModel]

    var onFinished: () -> Void

    @State private var name: String = ""
    @FocusState private var isFieldFocused: Bool

    private let maxLength = 12

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 56))
                        .foregroundStyle(.white.opacity(0.85))

                    Text("你叫什麼名字？")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    TextField("", text: $name)
                        .placeholder(when: name.isEmpty) {
                            Text("冒險者").foregroundStyle(.white.opacity(0.4))
                        }
                        .font(.title3)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .focused($isFieldFocused)
                        .onChange(of: name) { _, newValue in
                            if newValue.count > maxLength {
                                name = String(newValue.prefix(maxLength))
                            }
                        }
                        .padding(.horizontal, 40)

                    Text("可留空，之後無法更改")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Button {
                    save()
                } label: {
                    Text("確定，出發")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 48)
            }
        }
        .onAppear { isFieldFocused = true }
    }

    private func save() {
        guard let player = players.first else { onFinished(); return }
        player.heroName = name.trimmingCharacters(in: .whitespaces)
        try? context.save()
        onFinished()
    }
}

// MARK: - Placeholder Helper

private extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: .center) {
            if shouldShow { placeholder() }
            self
        }
    }
}
