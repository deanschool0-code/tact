import SwiftData
import SwiftUI

/// S10 entry from Home: add the chat, then check.
struct VibeCheckView: View {
    @State private var lines: [ChatLine] = []
    @State private var go = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                Text("An honest read on how it's going — from the text alone. No flattery.")
                    .font(Theme.Font.footnote).foregroundStyle(Theme.textMuted)
                ChatInputSection(lines: $lines)
                if lines.count >= 2 {
                    PrimaryButton(title: "Check the vibe", systemImage: ToolKind.vibe.systemImage) { go = true }
                } else if !lines.isEmpty {
                    Text("Add a few more messages for a fair read.").font(Theme.Font.caption).foregroundStyle(Theme.textMuted)
                }
            }
            .padding(Theme.Space.l)
        }
        .scrollDismissesKeyboard(.interactively)
        .screen()
        .navigationTitle("Vibe check")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $go) { VibeResultView(lines: lines) }
    }
}

struct VibeResultView: View {
    let lines: [ChatLine]
    @State private var result: VibeResult?
    @State private var loading = false
    @State private var error: String?
    @EnvironmentObject private var app: AppState
    @Environment(\.modelContext) private var context

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                if let error { ErrorBanner(message: error) { Task { await run() } } }
                if loading && result == nil {
                    HStack { Spacer(); ProgressView("Reading the room…").tint(Theme.accent); Spacer() }
                        .padding(.top, Theme.Space.xxl)
                }
                if let r = result {
                    HStack { Spacer(); MeterView(value: r.interest, label: "interest"); Spacer() }
                        .padding(.top, Theme.Space.m)
                    Text(r.summary).font(Theme.Font.body).foregroundStyle(Theme.text)
                    if r.boundary == true {
                        InfoLine(systemImage: "hand.raised.fill",
                                 text: "Looks like they want space. Best move: respect it.", color: Theme.warning)
                            .card(padding: Theme.Space.m)
                    }
                    flags("Green flags", r.greenFlags, "checkmark.circle.fill", Theme.success)
                    flags("Red flags", r.redFlags, "exclamationmark.circle.fill", Theme.danger)
                    VStack(alignment: .leading, spacing: Theme.Space.s) {
                        SectionTitle(text: "Next move")
                        Text(r.nextMove).font(Theme.Font.headline).foregroundStyle(Theme.text)
                    }
                    .card()
                    NavigationLink {
                        ResultsView(kind: .reply, lines: lines, text: "", tone: .chill, goal: .keepGoing, extra: r.nextMove)
                    } label: {
                        Label("Write a reply for this", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(Theme.Space.l)
        }
        .screen()
        .navigationTitle("Vibe check")
        .navigationBarTitleDisplayMode(.inline)
        .task { if result == nil && !loading { await run() } }
    }

    @ViewBuilder
    private func flags(_ title: String, _ items: [String], _ icon: String, _ color: Color) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                SectionTitle(text: title)
                ForEach(items, id: \.self) { InfoLine(systemImage: icon, text: $0, color: color) }
            }
            .card()
        }
    }

    @MainActor
    private func run() async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            let (r, q) = try await APIClient.shared.generate(GenerateRequest(kind: .vibe, lines: lines), as: VibeResult.self)
            withAnimation { result = r }
            app.quota = q
            app.remember(kind: .vibe, title: "Interest \(r.interest)/100",
                         outputs: [r.summary, "Next: " + r.nextMove], in: context)
        } catch {
            self.error = app.message(for: error)
        }
    }
}
