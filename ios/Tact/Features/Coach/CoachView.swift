import SwiftUI

/// S12: ask a socially smart friend.
struct CoachView: View {
    @State private var turns: [CoachTurn] = []
    @State private var draft = ""
    @State private var sending = false
    @State private var error: String?
    @FocusState private var focused: Bool
    @EnvironmentObject private var app: AppState

    private let starters = [
        "How do I ask them out without it being weird?",
        "They take hours to reply. Should I wait to text back?",
        "What's a good first date idea in the city?",
        "How do I recover from a dry conversation?",
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Space.m) {
                        if turns.isEmpty {
                            EmptyStateView(systemImage: "graduationcap.fill", title: "Ask the coach",
                                           message: "Texting, dates, mixed signals — ask anything. Straight answers, no games.")
                            ForEach(starters, id: \.self) { s in
                                Button { send(s) } label: {
                                    Text(s).font(Theme.Font.footnote).foregroundStyle(Theme.text)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .card(padding: Theme.Space.m)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        ForEach(turns) { t in
                            HStack {
                                if t.role == "user" { Spacer(minLength: 40) }
                                Text(t.text)
                                    .font(Theme.Font.body)
                                    .foregroundStyle(t.role == "user" ? Theme.onBubbleMe : Theme.text)
                                    .textSelection(.enabled)
                                    .padding(.horizontal, 14).padding(.vertical, 10)
                                    .background(t.role == "user" ? Theme.bubbleMe : Theme.surface2,
                                                in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                if t.role != "user" { Spacer(minLength: 40) }
                            }
                            .id(t.id)
                        }
                        if sending {
                            HStack { ProgressView().tint(Theme.accent); Text("Thinking…").font(Theme.Font.caption).foregroundStyle(Theme.textMuted) }
                        }
                        if let error { ErrorBanner(message: error) }
                    }
                    .padding(Theme.Space.l)
                }
                .onChange(of: turns.count) { _, _ in
                    if let last = turns.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            .scrollDismissesKeyboard(.interactively)

            HStack(spacing: Theme.Space.s) {
                TextField("Ask anything…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .focused($focused)
                    .padding(12)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.borderInput, lineWidth: 1))
                Button { send(draft) } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 34)).foregroundStyle(Theme.accent)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sending)
                .accessibilityLabel("Send")
            }
            .padding(Theme.Space.m)
            .background(Theme.bg)
        }
        .screen()
        .navigationTitle("Coach")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !turns.isEmpty { Button("New") { turns = []; error = nil } }
            }
        }
    }

    private func send(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !sending else { return }
        turns.append(CoachTurn(role: "user", text: t))
        draft = ""
        Task { await ask() }
    }

    @MainActor
    private func ask() async {
        sending = true
        error = nil
        defer { sending = false }
        do {
            let (reply, q) = try await APIClient.shared.coach(turns, context: nil)
            turns.append(CoachTurn(role: "assistant", text: reply))
            app.quota = q
        } catch {
            self.error = app.message(for: error)
        }
    }
}
