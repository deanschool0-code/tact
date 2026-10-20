import SwiftUI

/// S05 + S06: chat in, tone and goal, then results.
struct ReplyFlowView: View {
    @AppStorage(Pref.defaultTone) private var defaultTone = Tone.chill.rawValue
    @State private var lines: [ChatLine] = []
    @State private var tone: Tone = .chill
    @State private var goal: Goal = .keepGoing
    @State private var extra = ""
    @State private var showResults = false
    @State private var didSetTone = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                ChatInputSection(lines: $lines)

                if !lines.isEmpty {
                    ToneGoalPicker(tone: $tone, goal: $goal, extra: $extra)

                    PrimaryButton(title: "Write my reply", systemImage: "wand.and.stars") { showResults = true }
                        .disabled(!lines.contains { $0.from == .them })

                    if !lines.contains(where: { $0.from == .them }) {
                        Text("Add at least one message from them.").font(Theme.Font.caption).foregroundStyle(Theme.warning)
                    }

                    NavigationLink {
                        VibeResultView(lines: lines)
                    } label: {
                        Label("Check the vibe first", systemImage: ToolKind.vibe.systemImage)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .font(Theme.Font.footnote.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .padding(Theme.Space.l)
        }
        .scrollDismissesKeyboard(.interactively)
        .screen()
        .navigationTitle("Reply")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showResults) {
            ResultsView(kind: .reply, lines: lines, text: "", tone: tone, goal: goal, extra: extra)
        }
        .onAppear {
            if !didSetTone { tone = Tone(rawValue: defaultTone) ?? .chill; didSetTone = true }
        }
    }
}

struct ToneGoalPicker: View {
    @Binding var tone: Tone
    @Binding var goal: Goal
    @Binding var extra: String
    var showGoal = true

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            SectionTitle(text: "Vibe")
            ChipFlow(items: Tone.allCases) { t in
                Chip(title: t.label, systemImage: t.systemImage, isOn: tone == t) { tone = t }
            }
            if showGoal {
                SectionTitle(text: "Goal").padding(.top, Theme.Space.s)
                ChipFlow(items: Goal.allCases) { g in
                    Chip(title: g.label, isOn: goal == g) { goal = g }
                }
            }
            TextField("Anything it should know? (optional)", text: $extra, axis: .vertical)
                .lineLimit(1...3)
                .padding(12)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.sm).stroke(Theme.borderInput, lineWidth: 1))
                .padding(.top, Theme.Space.s)
        }
    }
}
